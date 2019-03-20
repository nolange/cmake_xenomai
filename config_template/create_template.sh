#!/bin/sh
set -e
set -u
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
    sed -e 's,get_filename_component(PACKAGE_PREFIX_DIR "${CMAKE_CURRENT_LIST_DIR}/[^"]*" ABSOLUTE),get_filename_component(PACKAGE_PREFIX_DIR "${CMAKE_CURRENT_LIST_DIR}/../../@lib_to_prefix@" ABSOLUTE),' -i "$path"/xenomai-config.cmake
    sed -e '/get_filename_component(_IMPORT_PREFIX .* PATH)/d' \
        -e 's,^# Compute the installation prefix relative to this file.,# Compute the installation prefix relative to this file.\nget_filename_component(_IMPORT_PREFIX "${CMAKE_CURRENT_LIST_DIR}/../../@lib_to_prefix@" ABSOLUTE),' \
           -i "$path"/xenomai-targets.cmake

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
  createconfigfiles $TEMPDIR/cobalt   -DXENOMAI_CORE_TYPE_COBALT=true "$SOURCEDIR"
  createconfigfiles $TEMPDIR/mercury  -DXENOMAI_CORE_TYPE_MERCURY=true "$SOURCEDIR"
  find $TEMPDIR/mercury $TEMPDIR/cobalt -type f -name '*.cmake' -exec mv "{}" "{}.in" \;

  ( cd $TEMPDIR
    cp --parents cobalt/xenomai-targets.cmake.in cobalt/xenomai-targets-noconfig.cmake.in $TARGETDIR/.
    cp --parents mercury/xenomai-targets.cmake.in mercury/xenomai-targets-noconfig.cmake.in $TARGETDIR/.
    rm cobalt/xenomai-targets.cmake.in cobalt/xenomai-targets-noconfig.cmake.in
    cp  cobalt/*.cmake.in $TARGETDIR/.
    cp "$SOURCEDIR"/install_cmakeconfig.sh $TARGETDIR/.
  )
)
