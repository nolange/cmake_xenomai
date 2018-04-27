# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file Copyright.txt or https://cmake.org/licensing for details.

#.rst:
# FindXenomai
# ---------
#
# Locate the Xenomai Development files.
#
# Imported targets
# ^^^^^^^^^^^^^^^^
#
# This module defines the following :prop_tgt:`IMPORTED` targets:
#
#
# Xenomai Frameworks, only one will be available
#
# ``xenomai::cobalt``
#   The Xenomai Framework using the realtime Dual-Kernel. This
#   is also a skin, but does never include further targets
#   automatically
# ``xenomai::mercury``
#   The Xenomai Framework using regular Linux
#   This one should not be used directly
#
# Xenomai optional modules
#
# ``xenomai::modechk``
#   The optional modecheck library for the realtime Dual-Kernel
# ``xenomai::bootstrap``
#   Bootstrap code to initialise Xenomai
#   Prefer to live without it if possible (TODO: Readme)
#
# Xenomai skins
#
# ``xenomai::posix``
#   Posix skin for the detected Xenomai kernel
# ``xenomai::vxworks``, ``xenomai::psos``, ``xenomai::alchemy``, `xenomai::smokey``
#   Diverse Realtime Skins for Xenomai
#
# The ``xenomai::posix`` target and other skins check the variable
# ``XENOMAI_SKIP_MODECHECK``, if it does not resolve to true,
# then the target will include the modecheck library if available.
#
# The ``xenomai::cobalt`` target will never include the modecheck or bootstrap library.
#
#  
# Result variables
# ^^^^^^^^^^^^^^^^
#
# This module will set the following variables in your project:
#
# ``XENOMAI_FOUND``
#   Found the Xenomai framework
# ``XENOMAI_CORE_TYPE``
#   the kernel configuration, either ``Cobalt`` or ``Mercury``
# ``XENOMAI_CORE_TYPE_COBALT`` or ``XENOMAI_CORE_TYPE_MERCURY``
#   depending on the kernel configuration
# ``XENOMAI_VERSION``
#   Version of the Xenomai Installation (Maj.Min.Patch)
# ``XENOMAI_VERSION_NAME``
#   Full Name of the Xenomai version
#
# Some more variables are set, but none of these is considered
# to be used externally for now.
#
# Cache variables
# ^^^^^^^^^^^^^^^
#
# The following cache variables may also be set:
#
# ``XENOMAI_ROOT``
#   The root directory of the Xenomai installation (may also be
#   set as an environment variable)
#
#
# Example usage
# ^^^^^^^^^^^^^
#
# ::
#     # Versions < 3 are not testet and very likely wont work
#     find_package(Xenomai 3.0 REQUIRED)
#
#     # Use whatever Xenomai kernel is avaiable,
#     # use modecheck library if available
#     add_executable(xenomai_anykernel foo.cc)
#     target_link_libraries(xenomai_anykernel xenomai::xenomai)
#
#     # depend on Cobalt, fail if this kernel is missing
#     add_executable(xenomai_cobalt foo.cc)
#     target_link_libraries(xenomai_cobalt xenomai::cobalt)
#
# Minimal required CMake Version is 3.0,
# several features are only fully usable with 3.1

if(NOT _FIND_XENO_DIR)
  set(_FIND_XENO_DIR "${CMAKE_CURRENT_LIST_DIR}")
endif()
# return if already set?

set(XENOMAI_FOUND false)

# allow setting hints with env or cmake variables
set(__XENOMAI_INCLUDE_HINTS)
set(__XENOMAI_LIBRARY_HINTS)
if(NOT "$ENV{XENOMAI_ROOT}" STREQUAL "")
  set(__XENOMAI_INCLUDE_HINTS "$ENV{XENOMAI_ROOT}/include")
  set(__XENOMAI_LIBRARY_HINTS "$ENV{XENOMAI_ROOT}/lib")
endif()
if(XENOMAI_ROOT)
  set(__XENOMAI_INCLUDE_HINTS "${__XENOMAI_INCLUDE_HINTS} ${XENOMAI_ROOT}/include")
  set(__XENOMAI_LIBRARY_HINTS "${__XENOMAI_LIBRARY_HINTS} ${XENOMAI_ROOT}/lib")
endif()
if(__XENOMAI_INCLUDE_HINTS)
  set(__XENOMAI_INCLUDE_HINTS "HINTS ${__XENOMAI_INCLUDE_HINTS}")
  set(__XENOMAI_LIBRARY_HINTS "HINTS ${__XENOMAI_LIBRARY_HINTS}")
endif()

find_path(XENOMAI_INCLUDE_DIR xeno_config.h
  ${__XENOMAI_INCLUDE_HINTS}
  PATH_SUFFIXES xenomai xenomai/include
)

find_library(XENOMAI_COBALT_LIBRARY NAMES cobalt
  DOC "Xenomai cobalt library path"
  ${__XENOMAI_LIBRARY_HINTS}
  PATH_SUFFIXES xenomai/lib
)

find_library(XENOMAI_MERCURY_LIBRARY NAMES mercury
  DOC "Xenomai mercury library path"
  ${__XENOMAI_LIBRARY_HINTS}
  PATH_SUFFIXES xenomai/lib
)

mark_as_advanced(XENOMAI_INCLUDE_DIR XENOMAI_COBALT_LIBRARY XENOMAI_MERCURY_LIBRARY)

unset(__XENOMAI_INCLUDE_HINTS)
unset(__XENOMAI_LIBRARY_HINTS)

if(XENOMAI_COBALT_LIBRARY)
  get_filename_component(__XENOMAI_LIBRARY_PATH "${XENOMAI_COBALT_LIBRARY}" DIRECTORY)
elseif(XENOMAI_MERCURY_LIBRARY)
  get_filename_component(__XENOMAI_LIBRARY_PATH "${XENOMAI_MERCURY_LIBRARY}" DIRECTORY)
endif()

set(XENOMAI_CORE_TYPE)
set(XENOMAI_CORE_TYPE_COBALT)
set(XENOMAI_CORE_TYPE_MERCURY)
set(__XENOMAI_COMPILE_DEFINITIONS)
set(__XENOMAI_INCLUDE_DIRS)
set(__XENOMAI_LINK_LIBRARIES)
set(XENOMAI_VERSION)
set(XENOMAI_VERSION_NAME)
set(XENOMAI_UAPI_LEVEL)
unset(__XENOMAI_COMPILE_POSIX_DEFINITIONS)
unset(__XENOMAI_LINK_POSIX_LIBRARIES)
unset(XENOMAI_VXWORKS_LIBRARY)
unset(XENOMAI_PSOS_LIBRARY)
unset(XENOMAI_ALCHEMY_LIBRARY)
unset(XENOMAI_SMOKEY_LIBRARY)

find_library(XENOMAI_MODECHK_LIBRARY NAMES modechk
  DOC "Xenomai modecheck library path"
  HINTS ${__XENOMAI_LIBRARY_PATH}
)
find_library(XENOMAI_COPPERPLATE_LIBRARY NAMES copperplate
  DOC "Xenomai copperplate library path"
  HINTS ${__XENOMAI_LIBRARY_PATH}
)
if (XENOMAI_COPPERPLATE_LIBRARY)
  find_library(XENOMAI_VXWORKS_LIBRARY NAMES vxworks
    DOC "Xenomai VxWorks skin library path"
    HINTS ${__XENOMAI_LIBRARY_PATH}
  )
  find_library(XENOMAI_PSOS_LIBRARY NAMES psos
    DOC "Xenomai PsOs skin library path"
    HINTS ${__XENOMAI_LIBRARY_PATH}
  )
  find_library(XENOMAI_ALCHEMY_LIBRARY NAMES alchemy
    DOC "Xenomai Alchemy skin library path"
    HINTS ${__XENOMAI_LIBRARY_PATH}
  )
  find_library(XENOMAI_SMOKEY_LIBRARY NAMES smokey
    DOC "Xenomai Smokey skin library path"
    HINTS ${__XENOMAI_LIBRARY_PATH}
  )
endif()
mark_as_advanced(XENOMAI_MODECHK_LIBRARY XENOMAI_COPPERPLATE_LIBRARY XENOMAI_VXWORKS_LIBRARY
  XENOMAI_PSOS_LIBRARY XENOMAI_ALCHEMY_LIBRARY XENOMAI_SMOKEY_LIBRARY)



if(XENOMAI_COBALT_LIBRARY)
  set(XENOMAI_CORE_TYPE Cobalt)
  set(XENOMAI_CORE_TYPE_COBALT true)
  set(__XENOMAI_COMPILE_DEFINITIONS __COBALT__)
  set(__XENOMAI_INCLUDE_DIRS "${XENOMAI_INCLUDE_DIR}/cobalt" "${XENOMAI_INCLUDE_DIR}")
  set(__XENOMAI_LINK_LIBRARIES "${XENOMAI_COBALT_LIBRARY}")

  set(__XENOMAI_COMPILE_POSIX_DEFINITIONS "__COBALT_WRAP__")
  set(__XENOMAI_LINK_POSIX_LIBRARIES "-Wl,@${__XENOMAI_LIBRARY_PATH}/cobalt.wrappers")

elseif(XENOMAI_MERCURY_LIBRARY)
  set(XENOMAI_CORE_TYPE Mercury)
  set(XENOMAI_CORE_TYPE_MERCURY true)
  set(__XENOMAI_COMPILE_DEFINITIONS __MERCURY__)
  set(__XENOMAI_INCLUDE_DIRS "${XENOMAI_INCLUDE_DIR}/mercury" "${XENOMAI_INCLUDE_DIR}")
  set(__XENOMAI_LINK_LIBRARIES "${XENOMAI_MERCURY_LIBRARY}")

endif()

function(_xeno_get_version)
  # Compile a small programm, this will also test whether the include paths are correctly setup
  # the version variable is created as a C-String, and then later the executable is parsed.
  # Note that when crosscompiling, the created program can't be executed

  set(file "${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/tmp/xenomai_version")
  string(REGEX REPLACE "([^;]+)" "-D\\1" _XENO_LIST "${__XENOMAI_COMPILE_DEFINITIONS} ${__XENOMAI_COMPILE_POSIX_DEFINITIONS}")
  try_compile(_xeno_compiled "${CMAKE_BINARY_DIR}" "${_FIND_XENO_DIR}/FindXenomai_Version.c"
    CMAKE_FLAGS 
      "-DINCLUDE_DIRECTORIES=${__XENOMAI_INCLUDE_DIRS}"
    COMPILE_DEFINITIONS ${_XENO_LIST}
    LINK_LIBRARIES ${__XENOMAI_LINK_POSIX_LIBRARIES} ${__XENOMAI_LINK_LIBRARIES}
    COPY_FILE "${file}")

  if (_xeno_compiled)
    # Filter out the INFO: strings
    file(STRINGS "${file}"
      _XENO_ID_STRINGS LIMIT_COUNT 38
      REGEX "INFO:[A-Za-z0-9_]+\\[[^]]*\\]")

    file(REMOVE "${file}")

    # find out variables
    foreach(info ${_XENO_ID_STRINGS})
      if("${info}" MATCHES "INFO:version\\[([^]\"]*)\\]")
        string(REGEX REPLACE "^0+([0-9])" "\\1" _XENO_VERSION "${CMAKE_MATCH_1}")
        string(REGEX REPLACE "\\.0+([0-9])" ".\\1" _XENO_VERSION "${_XENO_VERSION}")
        set(XENOMAI_VERSION ${_XENO_VERSION} PARENT_SCOPE)
      endif()
      if("${info}" MATCHES "INFO:version_name\\[([^]\"]*)\\]")
        string(REGEX REPLACE "^0+([0-9])" "\\1" _XENO_VERSION_NAME "${CMAKE_MATCH_1}")
        set(XENOMAI_VERSION_NAME ${_XENO_VERSION_NAME} PARENT_SCOPE)
      endif()
      if("${info}" MATCHES "INFO:uapi_level\\[([^]\"]*)\\]")
        string(REGEX REPLACE "^0+([0-9])" "\\1" _XENO_UAPI_LEVEL "${CMAKE_MATCH_1}")
        string(REGEX REPLACE "\\.0+([0-9])" ".\\1" _XENO_UAPI_LEVEL "${_XENO_UAPI_LEVEL}")
        set(XENOMAI_UAPI_LEVEL ${_XENO_UAPI_LEVEL} PARENT_SCOPE)
      endif()
    endforeach()
  endif()
  
endfunction()

_xeno_get_version()

include(FindPackageHandleStandardArgs)
# Note that the first variable is displayed
# set(__XENOMAI_DISPLAY ${XENOMAI_CORE_TYPE})
find_package_handle_standard_args(xenomai REQUIRED_VARS XENOMAI_CORE_TYPE __XENOMAI_LIBRARY_PATH __XENOMAI_COMPILE_DEFINITIONS __XENOMAI_INCLUDE_DIRS __XENOMAI_LINK_LIBRARIES XENOMAI_INCLUDE_DIR
                                     VERSION_VAR XENOMAI_VERSION)
# TODO: Write out a cmake file as cache?
if(XENOMAI_FOUND)
  cmake_policy(PUSH)
  cmake_policy(VERSION 2.6)
  set(_threadlib "Threads::Threads")
  if(CMAKE_VERSION VERSION_LESS 3.1)
    set(_threadlib "${CMAKE_THREAD_LIBS_INIT}")
  endif()


  if (NOT TARGET xenomai::cobalt AND XENOMAI_COBALT_LIBRARY)
    message("d${XENOMAI_COBALT_LIBRARY}")
    add_library(xenomai::cobalt SHARED IMPORTED)

    set_target_properties(xenomai::cobalt PROPERTIES
      INTERFACE_COMPILE_DEFINITIONS "__COBALT__"
      INTERFACE_INCLUDE_DIRECTORIES "${XENOMAI_INCLUDE_DIR}/cobalt;${XENOMAI_INCLUDE_DIR}"
      INTERFACE_LINK_LIBRARIES "${_threadlib};-lrt"
      IMPORTED_LOCATION "${XENOMAI_COBALT_LIBRARY}"
      IMPORTED_SONAME_NOCONFIG "libcobalt.so"
    )
  endif()

  if (NOT TARGET xenomai::modechk AND XENOMAI_MODECHK_LIBRARY)
    add_library(xenomai::modechk SHARED IMPORTED)

    set_target_properties(xenomai::modechk PROPERTIES
      INTERFACE_LINK_LIBRARIES "-Wl,@${__XENOMAI_LIBRARY_PATH}/modechk.wrappers;${_threadlib};-lrt"
      IMPORTED_LOCATION "${XENOMAI_MODECHK_LIBRARY}"
    )
  endif()

  if (NOT TARGET xenomai::mercury AND XENOMAI_MERCURY_LIBRARY)
    add_library(xenomai::mercury SHARED IMPORTED)

    set_target_properties(xenomai::mercury PROPERTIES
      INTERFACE_COMPILE_DEFINITIONS "__MERCURY__"
      INTERFACE_INCLUDE_DIRECTORIES "${XENOMAI_INCLUDE_DIR}/mercury;${XENOMAI_INCLUDE_DIR}"
      INTERFACE_LINK_LIBRARIES "${_threadlib};-lrt"
      IMPORTED_LOCATION "${XENOMAI_MERCURY_LIBRARY}"
    )
  endif()

  if (NOT TARGET xenomai::posix)
    if (TARGET xenomai::cobalt)
      # Create imported target xenomai::posix
      message("p${XENOMAI_COBALT_LIBRARY}")
      add_library(xenomai::posix INTERFACE IMPORTED)

      set_target_properties(xenomai::posix PROPERTIES
        INTERFACE_LINK_LIBRARIES "xenomai::cobalt"
      )
    elseif(TARGET xenomai::mercury)
      # Create imported target xenomai::posix
      add_library(xenomai::posix INTERFACE IMPORTED)

      set_target_properties(xenomai::posix PROPERTIES
        INTERFACE_LINK_LIBRARIES "xenomai::mercury"
      )
    endif()
  endif()

  if (NOT TARGET xenomai::legacy_bootstrap AND EXISTS "${__XENOMAI_LIBRARY_PATH}/xenomai/bootstrap.o" AND EXISTS "${__XENOMAI_LIBRARY_PATH}/xenomai/bootstrap-pic.o")
    # Create imported target xenomai::legacy_bootstrap
    add_library(xenomai::legacy_bootstrap INTERFACE IMPORTED)

    set_target_properties(xenomai::legacy_bootstrap PROPERTIES
      INTERFACE_LINK_LIBRARIES "\$<\$<STREQUAL:\$<TARGET_PROPERTY:TYPE>,SHARED_LIBRARY>:${__XENOMAI_LIBRARY_PATH}/xenomai/bootstrap-pic.o>;\$<\$<STREQUAL:\$<TARGET_PROPERTY:TYPE>,EXECUTABLE>:${__XENOMAI_LIBRARY_PATH}/xenomai/bootstrap.o>"
    )

    # Create imported target xenomai::legacy_bootstrap_wrap
    add_library(xenomai::legacy_bootstrap_wrap INTERFACE IMPORTED)

    set_target_properties(xenomai::legacy_bootstrap_wrap PROPERTIES
      INTERFACE_LINK_LIBRARIES "\$<\$<STREQUAL:\$<TARGET_PROPERTY:TYPE>,EXECUTABLE>:-Wl,--wrap=main,--dynamic-list=${__XENOMAI_LIBRARY_PATH}/dynlist.ld>"
    )
  endif()

  if (NOT TARGET xenomai::copperplate AND XENOMAI_COPPERPLATE_LIBRARY)
    if (TARGET xenomai::cobalt)
      # Create imported target xenomai::copperplate
      add_library(xenomai::copperplate SHARED IMPORTED)
      set_target_properties(xenomai::copperplate PROPERTIES
        INTERFACE_LINK_LIBRARIES "xenomai::cobalt"
        IMPORTED_LOCATION "${XENOMAI_COPPERPLATE_LIBRARY}"
      )
    elseif(TARGET xenomai::mercury)
      # Create imported target xenomai::copperplate
      add_library(xenomai::copperplate SHARED IMPORTED)
      set_target_properties(xenomai::copperplate PROPERTIES
        INTERFACE_LINK_LIBRARIES "xenomai::mercury"
        IMPORTED_LOCATION "${XENOMAI_COPPERPLATE_LIBRARY}"
      )
    endif()
  endif()

  foreach(_skin Vxworks Psos Alchemy Smokey)
    string(TOLOWER ${_skin} _lbname)
    string(TOUPPER ${_skin} _ubname)

    if (TARGET xenomai::copperplate AND NOT TARGET xenomai::${_lbname} AND XENOMAI_${_ubname}_LIBRARY)
      add_library(xenomai::${_lbname} SHARED IMPORTED)

      set_target_properties(xenomai::${_lbname} PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${XENOMAI_INCLUDE_DIR}/${_lbname}"
        INTERFACE_LINK_LIBRARIES "xenomai::copperplate"
        IMPORTED_LOCATION "${XENOMAI_${_ubname}_LIBRARY}"
      )
    endif()
  endforeach()

  unset(_lbname)
  unset(_ubname)
  unset(_skin)
  cmake_policy(POP)
endif()

unset(__XENOMAI_COMPILE_DEFINITIONS)
unset(__XENOMAI_INCLUDE_DIRS)
unset(__XENOMAI_LINK_LIBRARIES)

if(NOT XENOMAI_FOUND)
  return()
endif()

if(CMAKE_VERSION VERSION_LESS 3.5)
include(CMakeParseArguments)
endif()

function(xenomai_target_bootstrap target)

  set(_fileprefix "${CMAKE_CURRENT_BINARY_DIR}/generated/xenomai_bootstrap")
  # __real_main?
  file(WRITE "${_fileprefix}_main.c" "#ifdef main\n#undef main\n#endif\n#define _XENOMAI_BOOTSTRAP_DEFINE_MAINWRAPPER __real_main\n#define _XENOMAI_BOOTSTRAP_WEAKREF_MAINWRAPPER main\n#include <xenomai/bootstrap-template.h>")
  file(WRITE "${_fileprefix}_shl.c" "#define _XENOMAI_BOOTSTRAP_DSO\n#include <xenomai/bootstrap-template.h>")
  file(WRITE "${_fileprefix}.c" "#include <xenomai/bootstrap-template.h>")

  get_target_property(ttype ${target} TYPE)

  cmake_parse_arguments(XBS "NO_FALLBACK" "MAIN;MAIN_WRAP" "SKINS" ${ARGN})
  set(_errors)

  if(XBS_MAIN AND NOT XBS_MAIN STREQUAL "NONE" AND NOT XBS_MAIN STREQUAL "SOURCE" AND NOT XBS_MAIN STREQUAL "PRECOMPILED")
    set(_errors ${_errors} "MAIN only support the values NONE, SOURCE and PRECOMPILED")
  endif()
  if(XBS_MAIN_WRAP AND NOT XBS_MAIN_WRAP STREQUAL "NONE" AND NOT XBS_MAIN_WRAP STREQUAL "MACRO" AND NOT XBS_MAIN_WRAP STREQUAL "LINKER")
    set(_errors ${_errors} "XBS_MAIN_WRAP only support the values NONE, MACRO and LINKER")
  endif()

  # the default is not working on CMake 3.0, so fallback to
  # the precompiled objects unless this was disabled
  if(CMAKE_VERSION VERSION_LESS 3.1)
    if(NOT XBS_MAIN OR XBS_MAIN STREQUAL "NONE" OR XBS_MAIN STREQUAL "SOURCE")
      if(XBS_NO_FALLBACK)
        set(_errors ${_errors} "MAIN NONE and MAIN SOURCE need atleast CMake 3.1")
      else()
        if(ttype STREQUAL EXECUTABLE)
          message(WARNING "xenomai_target_bootstrap: setting MAIN PRECOMPILED for ${target} (CMake Version less than 3.1)")
        endif()
        set(XBS_MAIN "PRECOMPILED")
          if(NOT XBS_MAIN_WRAP OR XBS_MAIN_WRAP STREQUAL "NONE" OR XBS_MAIN_WRAP STREQUAL "MACRO")
            set(XBS_MAIN_WRAP "LINKER")
            if(ttype STREQUAL EXECUTABLE)
            message(WARNING "xenomai_target_bootstrap: setting XBS_MAIN_WRAP LINKER for ${target} (CMake Version less than 3.1)")
          endif()
          endif()
      endif()
    endif()
  endif()

  if(_errors)
    message(SEND_ERROR "xenomai_target_bootstrap: ${_errors}")
    return()
  endif()

  if(XBS_MAIN STREQUAL "SOURCE")
    target_sources(${target} PRIVATE
      "$<$<STREQUAL:$<TARGET_PROPERTY:TYPE>,SHARED_LIBRARY>:${_fileprefix}_shl.c>"
      "$<$<STREQUAL:$<TARGET_PROPERTY:TYPE>,EXECUTABLE>:${_fileprefix}_main.c>"
    )

  elseif(XBS_MAIN STREQUAL "PRECOMPILED")
    target_link_libraries(${target} PRIVATE
      xenomai::legacy_bootstrap
    )

  else()
    target_sources(${target} PRIVATE
        "$<$<STREQUAL:$<TARGET_PROPERTY:TYPE>,SHARED_LIBRARY>:${_fileprefix}_shl.c>"
      "$<$<STREQUAL:$<TARGET_PROPERTY:TYPE>,EXECUTABLE>:${_fileprefix}.c>"
    )

  endif()

  if(XBS_MAIN_WRAP STREQUAL "MACRO")
    target_compile_definitions(${target} PRIVATE
        $<$<STREQUAL:$<TARGET_PROPERTY:TYPE>,EXECUTABLE>:main=__real_main>
    )

  elseif(XBS_MAIN_WRAP STREQUAL "LINKER")
    target_link_libraries(${target} PRIVATE
      xenomai::legacy_bootstrap_wrap
    )
  endif()

  set(_skins)
  foreach(skin ${XBS_SKINS})
    set(_skins ${_skins} "xenomai::${skin}")
  endforeach()

  if(_skins)
    target_link_libraries(${target} PRIVATE
      ${_skins}
    )
  endif()
endfunction()
