#!/bin/sh
TARGETDIR=$1
TARGETDIR=$(readlink -m "$TARGETDIR")

insertplaceholders() {
  local path
  for path; do
    # replace the path to the wrappers with the correct variable
    sed -e 's,/usr/local/lib,${_IMPORT_PREFIX}/${_xenomai_libdir},g' \
        -e 's,/usr/local/include,${_IMPORT_PREFIX}/${_xenomai_includedir},g' -i "$path"/xenomai-targets.cmake

    # support thread lib dependency for CMake 3.0
    sed -e 's,Threads::Threads,${_xenomai_threadlib},g' -i "$path"/xenomai-targets.cmake
    
    # replace relative paths with placeholders
    sed -e 's,${_IMPORT_PREFIX}/lib,${_IMPORT_PREFIX}/${_xenomai_libdir},g' \
        -e 's,${_IMPORT_PREFIX}/include,${_IMPORT_PREFIX}/${_xenomai_includedir},g' -i "$path"/xenomai-targets-noconfig.cmake

    # replace path to prefix with placeholder
    sed -e 's,get_filename_component(PACKAGE_PREFIX_DIR "${CMAKE_CURRENT_LIST_DIR}/[^"]*" ABSOLUTE),get_filename_component(PACKAGE_PREFIX_DIR "${CMAKE_CURRENT_LIST_DIR}/../../${_xenomai_pref_from_lib}" ABSOLUTE),' -i "$path"/xenomai-config.cmake

    sed -e 's,~#\([[:alpha:]_]*\)#~,@\1@,g' -i "$path"/xenomai-config.cmake

     # replace version and bitness with placeholder
    sed -e 's,"1.2.3","@PACKAGE_VERSION@",g' -e 's,"8\([ "]\),"@CMAKE_SIZEOF_VOID_P@\1,g' -i "$path"/xenomai-config-version.cmake
  done
}

CMAKE=cmake
createconfigfiles() {
  local TEMPDIR CMAKEDIR OUTDIR
  OUTDIR=$1; shift
(
  TEMPDIR=$(mktemp -d); trap "rm -rf $TEMPDIR" 0
  
  ( cd $TEMPDIR; "$CMAKE" "$@"; )
  DESTDIR=$TEMPDIR/inst make -C $TEMPDIR install
  CMAKEDIR=$TEMPDIR/inst/usr/local/lib/cmake/xenomai
  insertplaceholders $CMAKEDIR
  cp -r $CMAKEDIR/. ${OUTDIR}
)
}

(
  SOURCEDIR=$(pwd)
  TEMPDIR=$(mktemp -d); trap "rm -rf $TEMPDIR" 0
  mkdir $TEMPDIR/cobalt $TEMPDIR/mercury 
  createconfigfiles $TEMPDIR/cobalt -DXENOMAI_CORE_TYPE_COBALT=true "$SOURCEDIR"
  createconfigfiles $TEMPDIR/mercury -DXENOMAI_CORE_TYPE_MERCURY=true "$SOURCEDIR"
  find $TEMPDIR/mercury $TEMPDIR/cobalt -type f -name '*.cmake' -exec mv "{}" "{}.in" \;

  ( cd $TEMPDIR
    cp --parents cobalt/xenomai-targets.cmake.in cobalt/xenomai-targets-noconfig.cmake.in $TARGETDIR/.
    cp --parents mercury/xenomai-targets.cmake.in mercury/xenomai-targets-noconfig.cmake.in $TARGETDIR/.
    rm cobalt/xenomai-targets.cmake.in cobalt/xenomai-targets-noconfig.cmake.in
    cp  cobalt/*.cmake.in $TARGETDIR/.
    cp "$SOURCEDIR"/install_cmakeconfig.sh $TARGETDIR/.
  )
)
exit

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

mkdir -p out_templ/cobalt out_templ/mercury 
cp out/cmake_cobalt/*.cmake out_templ
rm out_templ/xenomai-targets.cmake out_templ/xenomai-targets-noconfig.cmake
cp out/cmake_cobalt/xenomai-targets.cmake out/cmake_cobalt/xenomai-targets-noconfig.cmake out_templ/cobalt
cp out/cmake_mercury/xenomai-targets.cmake out/cmake_mercury/xenomai-targets-noconfig.cmake out_templ/mercury
find out_templ -type f -name '*.cmake' -exec mv "{}" "{}.in" \;

fillplaceholders_old() {
  local file
  for file; do
    sed -e 's,@XENO_RELPREFPATH@,'"${XENO_RELPREFPATH}"',g' \
        -e 's,@XENO_RELLIBPATH@,'"${XENO_RELLIBPATH}"',g' \
        -e 's,@XENO_RELINCPATH@,'"${XENO_RELINCPATH}"',g' \
        -e 's,@CMAKE_VERSION_CODE@,'"${PACKAGE_VERSION}"',g' \
        -e 's,@CMAKE_SIZEOF_VOID_P@,'"${CMAKE_SIZEOF_VOID_P}"',g' -i "${file}"
  done
}

(
  cd out/cmake_cobalt/

# --prefix=/usr/xenomai --includedir=/usr/include/xenomai
ACONF_PREFIX=/usr/xenomai
ACONF_INCLUDE=/usr/include/xenomai
ACONV_LIBDIR=/usr/xenomai/lib
PACKAGE_VERSION="3.0.4"
CMAKE_SIZEOF_VOID_P=8

# test whether realpath supports the --relative-to flag 
[ "x$(realpath 2>&1 -m --relative-to=--xyz/zzt -- --xyz/z)" = "x../z" ] ||
  { echo 1>2 "no modern GNU realpath available"; exit 20; }


XENO_RELLIBPATH=$(realpath -m --relative-to="$ACONF_PREFIX" "$ACONV_LIBDIR")
XENO_RELINCPATH=$(realpath -m --relative-to="$ACONF_PREFIX" "$ACONF_INCLUDE")
# backtrace from Cmake file
XENO_RELPREFPATH=$(realpath -m --relative-to="$ACONV_LIBDIR/cmake/xenomai" "$ACONF_PREFIX")




fillplaceholders() {
  local file
  for file; do
    sed -e 's,@prefix@,'"${ACONF_PREFIX}"',g' \
        -e 's,@libdir@,'"${ACONV_LIBDIR}"',g' \
        -e 's,@includedir@,'"${ACONF_INCLUDE}"',g' \
        -e 's,@CMAKE_VERSION_CODE@,'"${PACKAGE_VERSION}"',g' \
        -e 's,@CMAKE_SIZEOF_VOID_P@,'"${CMAKE_SIZEOF_VOID_P}"',g' -i "${file}"
  done
}

fillplaceholders *.cmake
)

(
    cd out/cmake_mercury/

ACONF_PREFIX=/usr/xenomai
ACONF_INCLUDE=/usr/xenomai/include
ACONV_LIBDIR=/usr/xenomai/lib
PACKAGE_VERSION="3.0.4"
CMAKE_SIZEOF_VOID_P=8

XENO_RELLIBPATH=$(realpath -m --relative-to="$ACONF_PREFIX" "$ACONV_LIBDIR")
XENO_RELINCPATH=$(realpath -m --relative-to="$ACONF_PREFIX" "$ACONF_INCLUDE")
# backtrace from Cmake file
XENO_RELPREFPATH=$(realpath -m --relative-to="$ACONV_LIBDIR/cmake/xenomai" "$ACONF_PREFIX")


fillplaceholders() {
  local file
  for file; do
    sed -e 's,@prefix@,'"${ACONF_PREFIX}"',g' \
        -e 's,@libdir@,'"${ACONV_LIBDIR}"',g' \
        -e 's,@includedir@,'"${ACONF_INCLUDE}"',g' \
        -e 's,@PACKAGE_VERSION@,'"${PACKAGE_VERSION}"',g' \
        -e 's,@CMAKE_SIZEOF_VOID_P@,'"${CMAKE_SIZEOF_VOID_P}"',g' -i "${file}"
  done
}

fillplaceholders *.cmake

)
exit

cp /home/lano/code/xeno_cmake/config_template/out/cmake_cobalt/. /home/lano/buildroot/staging/usr/xenomai/lib/cmake/xenomai -r
cp /home/lano/code/xeno_cmake/config_template/out/cmake_mercury/. /usr/xenomai/lib/cmake/xenomai/ -r


# during xenomai installation
# Paths are based on the "prefix", CMake allows the installation to be relocatable,
# and thus creates variables representing the relocated prefix path
# the variables are PACKAGE_PREFIX_DIR for the config scripts themselfes,
# and _IMPORT_PREFIX during evaluation of the targets.
# 
# @XENO_RELPREFPATH@ rel path from the config file to CMAKE_INSTALL_PREFIX
# @XENO_RELINCPATH@  rel path from installation prefix to the headers
# @XENO_RELLIBPATH@  rel path from installation prefix to the libraries + wrappers
# @PACKAGE_VERSION@
sed -e 's,@XENO_RELPREFPATH@,../../../../,g' -i xenomai-config.cmake

sed -e 's,@XENO_RELLIBPATH@,lib,g' -e 's,@XENO_RELINCPATH@,../include,g' -i xenomai-targets.cmake
sed -e 's,@XENO_RELLIBPATH@,lib,g' -e 's,@XENO_RELINCPATH@,../include,g' -i xenomai-targets-noconfig.cmake
sed -e 's,@PACKAGE_VERSION@,3.0.4,g' -e 's,@CMAKE_SIZEOF_VOID_P@,8,g' xenomai-config-version.cmake


