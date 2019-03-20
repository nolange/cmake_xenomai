#!/bin/sh
set -e
set -u
SRCDIR=$(dirname "$(readlink -f "$0")")
printusage() {
cat << EOF
Usage: "$(basename $0)" [OPTION]... [--] TARGETPATH

Installs the CMake config files for Xenomai,
TARGETPATH should be the installed '<libpath>/cmake/xenomai'
of your installation.

Options:
  --with-core=<cobalt | mercury>
                          build for dual kernel or single image

  --prefix=PREFIX         install architecture-independent files in PREFIX
                          [/usr/xenomai]
  --exec-prefix=EPREFIX   install architecture-dependent files in EPREFIX
                          [PREFIX]

  --libdir=DIR            object code libraries [EPREFIX/lib]
  --includedir=DIR        C header files [PREFIX/include]

  --version=VER           Xenomai version, will attempt to autodetect
                          from header INCLUDEDIR/xeno_config.h
  --bitness=SIZEOFVP      Target size-of-void-pointer
EOF
  if [ -n "$1" ]; then exit $1; fi
}


TMP="`getopt -s sh -o '' --long with-core:,prefix:,exec-prefix:,libdir:,includedir:,version:,bitness: -n "$(basename $0)" -- "$@"`"
if [ $? != 0 ] ; then
  printusage 1>&2 1
fi

eval set -- "$TMP"

core=cobalt
prefix=/usr/xenomai
exec_prefix='${prefix}'
libdir='${exec_prefix}'/lib
includedir='${prefix}'/include
version='@CMAKE_VERSION_CODE@'
bitness=
do_version=
has_bitness=

while true ; do
  case "$1" in
    --with-core) core=$2; shift ;;
    --prefix) prefix=$2; shift ;;
    --exec-prefix) exec_prefix=$2; shift ;;
    --libdir) libdir=$2; shift ;;
    --includedir) includedir=$2; shift ;;
    --version) version=$2; do_version=1; shift ;;
    --bitness) bitness=$2; has_bitness=1; shift ;;

    --help) printusage; exit 0 ;;
    --) shift ; break ;;
    *) echo "$(basename $0): Script Error" 1>&2 ; exit 1 ;;
  esac
  shift
done

# [ -z "$do_version" ] || [ -n "$has_bitness" ] || { echo "Need to define bitness if version is set" 1>&2; printusage 1; }

[ -d "${1-}" ] || { echo "No valid TARGETPATH" 1>&2; printusage 1; }
targetpath=$1; shift

# make simple absolute paths from the variables
derefvar() {
  local var last
  var=$1
  last="x$1"
  while [ "$var" != "$last" ]; do
    last=$var
    var=$(eval "printf '%s' \"$var\"")
  done
  printf '%s' "$var"
}

# create relative path
torelpath() {
  local target common_part forward_part result
  target=${2}

  common_part=${1}
  result=

  test "x${common_part}" != "x" && test "x${target}" != "x" || return

  while test "x${target#$common_part}" = "x${target}"; do
      common_part=`dirname "$common_part"`
      result="../${result}"
  done

  forward_part=${target#${common_part}}
  forward_part=${forward_part#/}

  result="${result}${forward_part}"
  result=${result%/}

  printf '%s' "${result}"
}

prefix=$(derefvar "$prefix")
libdir=$(derefvar "$libdir")
includedir=$(derefvar "$includedir")

lib_to_prefix=$(torelpath "$libdir" "$prefix")
libdir_rel=$(torelpath "$prefix" "$libdir")
includedir_rel=$(torelpath "$prefix" "$includedir")

core_upper=$(printf "%s" $core | tr '[a-z]' '[A-Z]')

if [ -z "$do_version" ]; then
  autodetect_version=$(sed 2>/dev/null -n 's,.*\bVERSION[[:space:]"]*\([^[:space:]"]*\).*,\1,p' "$includedir"/xeno_config.h) &&
    { version=$autodetect_version; do_version=1; } || :
fi

TEMPDIR=$(mktemp -d); trap "rm -rf $TEMPDIR" 0
(
  cd "$SRCDIR"
for template in ${core}/xenomai-targets.cmake.in ${core}/xenomai-targets-noconfig.cmake.in xenomai-config.cmake.in xenomai-macros.cmake.in bootstrap-template.h ${do_version:+xenomai-config-version.cmake.in}; do
  tname=${template%.in}
  tname=${tname##*/}
  sed -e 's,@core@,'"$core"',g' \
    -e 's,@core_upper@,'"$core_upper"',g' \
    -e 's,@prefix@,'"$prefix"',g' \
    -e 's,@libdir@,'"$libdir"',g' \
    -e 's,@includedir@,'"$includedir"',g' \
    -e 's,@lib_to_prefix@,'"$lib_to_prefix"',g' \
    -e 's,@libdir_rel@,'"$libdir_rel"',g' \
    -e 's,@includedir_rel@,'"$includedir_rel"',g' \
    -e 's,@CMAKE_VERSION_CODE@,'"$version"',g' \
    -e 's,@CMAKE_SIZEOF_VOID_P@,'"$bitness"',g'  >"${TEMPDIR}"/${tname} "${template}" || exit 20
done
)
cp -r $TEMPDIR/. "${targetpath}"
