#!/bin/sh

insertplaceholders() {
  local path
  for path; do
    # replace the path to the wrappers with the correct variable
    sed -e 's,/usr/local/lib,${_IMPORT_PREFIX}/@XENO_RELLIBPATH@,g' \
        -e 's,/usr/local/include,${_IMPORT_PREFIX}/@XENO_RELINCPATH@,g' -i "$path"/xenomai-targets.cmake

    # support thread lib dependency for CMake 3.0
    sed -e 's,Threads::Threads,${_xenomai_threadlib},g' -i "$path"/xenomai-targets.cmake
    

    # replace relative paths with placeholders
    sed -e 's,${_IMPORT_PREFIX}/lib,${_IMPORT_PREFIX}/@XENO_RELLIBPATH@,g' \
        -e 's,${_IMPORT_PREFIX}/include,${_IMPORT_PREFIX}/@XENO_RELINCPATH@,g' -i "$path"/xenomai-targets-noconfig.cmake

    # replace path to prefix with placeholder
    sed -e 's,get_filename_component(PACKAGE_PREFIX_DIR "${CMAKE_CURRENT_LIST_DIR}/[^"]*" ABSOLUTE),get_filename_component(PACKAGE_PREFIX_DIR "${CMAKE_CURRENT_LIST_DIR}/@XENO_RELPREFPATH@" ABSOLUTE),' -i "$path"/xenomai-config.cmake

     # replace version and bitness with placeholder
    sed -e 's,"1.2.3","@XENO_VERSION@",g' -e 's,"8\([ "]\),"@XENO_BITNESS@\1,g' -i "$path"/xenomai-config-version.cmake
  done
}
(
  SOURCEDIR=$(pwd); OUTDIR=${SOURCEDIR}/out
  TEMPDIR=$(mktemp -d); trap "rm -rf $TEMPDIR" 0
  CMAKE=cmake
  CMAKEDIR=$TEMPDIR/inst/usr/local/lib/cmake/xenomai
  mkdir $OUTDIR

  ( cd $TEMPDIR; $CMAKE -DXENOMAI_CORE_TYPE_COBALT=true $SOURCEDIR; )
  DESTDIR=$TEMPDIR/inst make -C $TEMPDIR install
  insertplaceholders $CMAKEDIR
  cp -r $CMAKEDIR ${OUTDIR}/cmake_cobalt

  rm -rf ${TEMPDIR:-###}/*

  ( cd $TEMPDIR; $CMAKE -DXENOMAI_CORE_TYPE_MERCURY=true $SOURCEDIR; )
  DESTDIR=$TEMPDIR/inst make -C $TEMPDIR install
  insertplaceholders $CMAKEDIR
  cp -r $CMAKEDIR ${OUTDIR}/cmake_mercury
)

(
  cd out/cmake_cobalt/

# --prefix=/usr/xenomai --includedir=/usr/include/xenomai
ACONF_PREFIX=/usr/xenomai
ACONF_INCLUDE=/usr/include/xenomai
ACONV_LIBDIR=/usr/xenomai/lib

# test whether realpath supports the --relative-to flag 
[ "x$(realpath 2>&1 -m --relative-to=--xyz/zzt -- --xyz/z)" = "x../z" ] ||
  { echo 1>2 "no modern GNU realpath available"; exit 20; }


XENO_RELLIBPATH=$(realpath -m --relative-to="$ACONF_PREFIX" "$ACONV_LIBDIR")
XENO_RELINCPATH=$(realpath -m --relative-to="$ACONF_PREFIX" "$ACONF_INCLUDE")
# backtrace from Cmake file
XENO_RELPREFPATH=$(realpath -m --relative-to="$ACONV_LIBDIR/cmake/xenomai" "$ACONF_PREFIX")
XENO_VERSION="3.0.4"
XENO_BITNESS=8

fillplaceholders() {
  local file
  for file; do
    sed -e 's,@XENO_RELPREFPATH@,'"${XENO_RELPREFPATH}"',g' \
        -e 's,@XENO_RELLIBPATH@,'"${XENO_RELLIBPATH}"',g' \
        -e 's,@XENO_RELINCPATH@,'"${XENO_RELINCPATH}"',g' \
        -e 's,@XENO_VERSION@,'"${XENO_VERSION}"',g' \
        -e 's,@XENO_BITNESS@,'"${XENO_BITNESS}"',g' -i "${file}"
  done
}

fillplaceholders *.cmake
)

(
    cd out/cmake_mercury/

ACONF_PREFIX=/usr/xenomai
ACONF_INCLUDE=/usr/xenomai/include
ACONV_LIBDIR=/usr/xenomai/lib

XENO_RELLIBPATH=$(realpath -m --relative-to="$ACONF_PREFIX" "$ACONV_LIBDIR")
XENO_RELINCPATH=$(realpath -m --relative-to="$ACONF_PREFIX" "$ACONF_INCLUDE")
# backtrace from Cmake file
XENO_RELPREFPATH=$(realpath -m --relative-to="$ACONV_LIBDIR/cmake/xenomai" "$ACONF_PREFIX")
XENO_VERSION="3.0.4"
XENO_BITNESS=8

fillplaceholders() {
  local file
  for file; do
    sed -e 's,@XENO_RELPREFPATH@,'"${XENO_RELPREFPATH}"',g' \
        -e 's,@XENO_RELLIBPATH@,'"${XENO_RELLIBPATH}"',g' \
        -e 's,@XENO_RELINCPATH@,'"${XENO_RELINCPATH}"',g' \
        -e 's,@XENO_VERSION@,'"${XENO_VERSION}"',g' \
        -e 's,@XENO_BITNESS@,'"${XENO_BITNESS}"',g' -i "${file}"
  done
}

fillplaceholders *.cmake

)
# during xenomai installation
# Paths are based on the "prefix", CMake allows the installation to be relocatable,
# and thus creates variables representing the relocated prefix path
# the variables are PACKAGE_PREFIX_DIR for the config scripts themselfes,
# and _IMPORT_PREFIX during evaluation of the targets.
# 
# @XENO_RELPREFPATH@ rel path from the config file to CMAKE_INSTALL_PREFIX
# @XENO_RELINCPATH@  rel path from installation prefix to the headers
# @XENO_RELLIBPATH@  rel path from installation prefix to the libraries + wrappers
# @XENO_VERSION@
sed -e 's,@XENO_RELPREFPATH@,../../../../,g' -i xenomai-config.cmake

sed -e 's,@XENO_RELLIBPATH@,lib,g' -e 's,@XENO_RELINCPATH@,../include,g' -i xenomai-targets.cmake
sed -e 's,@XENO_RELLIBPATH@,lib,g' -e 's,@XENO_RELINCPATH@,../include,g' -i xenomai-targets-noconfig.cmake
sed -e 's,@XENO_VERSION@,3.0.4,g' -e 's,@XENO_BITNESS@,8,g' xenomai-config-version.cmake

