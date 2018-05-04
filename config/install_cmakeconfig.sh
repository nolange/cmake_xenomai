#!/bin/sh
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
bitness='@CMAKE_SIZEOF_VOID_P@'

while true ; do
  case "$1" in
    --with-core) core=$2; shift ;;
    --prefix) prefix=$2; shift ;;
    --exec-prefix) exec_prefix=$2; shift ;;
    --libdir) libdir=$2; shift ;;
    --includedir) includedir=$2; shift ;;
    --version) version=$2; shift ;;
    --bitness) bitness=$2; shift ;;

    --help) printusage; exit 0 ;;
    --) shift ; break ;;
    *) echo "$(basename $0): Script Error" 1>&2 ; exit 1 ;;
  esac
  shift
done

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

for template in ${core}/xenomai-targets.cmake.in ${core}/xenomai-targets-noconfig.cmake.in xenomai-config.cmake.in xenomai-config-version.cmake.in xenomai-macros.cmake.in; do
  tname=${template%.in}
  tname=${tname##*/}
  sed -e 's,@prefix@,'"$prefix"',g' \
    -e 's,@libdir@,'"$libdir"',g' \
    -e 's,@includedir@,'"$includedir"',g' \
    -e 's,@CMAKE_VERSION_CODE@,'"$version"',g' \
    -e 's,@CMAKE_SIZEOF_VOID_P@,'"$bitness"',g' ${template} >"${targetpath}"/${tname} || exit 20
done

