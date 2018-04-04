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
# ``Xenomai::Cobalt``
#   The Xenomai Framework using the realtime Dual-Kernel. This
#   is also a skin, but does never include further targets
#   automatically
# ``Xenomai::Mercury``
#   The Xenomai Framework using regular Linux
#   This one should not be used directly
#
# Xenomai optional modules
#
# ``Xenomai::ModeChk``
#   The optional modecheck library for the realtime Dual-Kernel
# ``Xenomai::Bootstrap``
#   Bootstrap code to initialise Xenomai
#   Prefer to live without it if possible (TODO: Readme)
#
# Xenomai skins
#
# ``Xenomai::Posix``
#   Posix skin for the detected Xenomai kernel
# ``Xenomai::Vxworks``, ``Xenomai::Psos``, ``Xenomai::Alchemy``, `Xenomai::Smokey``
#   Diverse Realtime Skins for Xenomai
#
# The ``Xenomai::Posix`` target and other skins check the variable
# ``XENOMAI_SKIP_MODECHECK``, if it does not resolve to true,
# then the target will include the modecheck library if available.
#
# The ``Xenomai::Cobalt`` target will never include the modecheck or bootstrap library.
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
#     target_link_libraries(xenomai_anykernel Xenomai::Xenomai)
#
#     # depend on Cobalt, fail if this kernel is missing
#     add_executable(xenomai_cobalt foo.cc)
#     target_link_libraries(xenomai_cobalt Xenomai::Cobalt)
#
#

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
find_package_handle_standard_args(Xenomai REQUIRED_VARS XENOMAI_CORE_TYPE __XENOMAI_LIBRARY_PATH __XENOMAI_COMPILE_DEFINITIONS __XENOMAI_INCLUDE_DIRS __XENOMAI_LINK_LIBRARIES XENOMAI_INCLUDE_DIR
                                     VERSION_VAR XENOMAI_VERSION)
                                     
if(XENOMAI_FOUND)
  set(XENOMAI_BOOTSTRAP_SRC
    $<$<STREQUAL:$<TARGET_PROPERTY:TYPE>,SHARED_LIBRARY>:${_FIND_XENO_DIR}/bootstrap-shl.c>
    $<$<STREQUAL:$<TARGET_PROPERTY:TYPE>,EXECUTABLE>:${_FIND_XENO_DIR}/bootstrap.c>
    )
  if (NOT TARGET Xenomai::Bootstrap AND EXISTS "${__XENOMAI_LIBRARY_PATH}/bootstrap.o" AND EXISTS "${__XENOMAI_LIBRARY_PATH}/bootstrap-pic.o")
    add_library(Xenomai::Bootstrap INTERFACE IMPORTED)

    # Aint CMake's syntax beautiful?
    set_target_properties(Xenomai::Bootstrap PROPERTIES
      INTERFACE_LINK_LIBRARIES "$<$<STREQUAL:$<TARGET_PROPERTY:TYPE>,SHARED_LIBRARY>:${__XENOMAI_LIBRARY_PATH}/bootstrap-pic.o>;$<$<STREQUAL:$<TARGET_PROPERTY:TYPE>,EXECUTABLE>:${__XENOMAI_LIBRARY_PATH}/bootstrap.o>;$<$<STREQUAL:$<TARGET_PROPERTY:TYPE>,EXECUTABLE>:-Wl,--wrap=main,--dynamic-list=${__XENOMAI_LIBRARY_PATH}/dynlist.ld>"
    )
  endif()
  if (NOT TARGET Xenomai::ModeChk AND XENOMAI_MODECHK_LIBRARY)
    add_library(Xenomai::ModeChk INTERFACE IMPORTED)

    set_target_properties(Xenomai::ModeChk PROPERTIES
      INTERFACE_LINK_LIBRARIES "-Wl,@${__XENOMAI_LIBRARY_PATH}/modechk.wrappers;${XENOMAI_MODECHK_LIBRARY}"
    )
  endif()

  if (NOT TARGET Xenomai::Cobalt AND XENOMAI_COBALT_LIBRARY)
    add_library(Xenomai::Cobalt INTERFACE IMPORTED)

    set_target_properties(Xenomai::Cobalt PROPERTIES
      INTERFACE_COMPILE_DEFINITIONS "${__XENOMAI_COMPILE_DEFINITIONS}"
      INTERFACE_INCLUDE_DIRECTORIES "${__XENOMAI_INCLUDE_DIRS}"
      INTERFACE_LINK_LIBRARIES "${__XENOMAI_LINK_LIBRARIES}"
    )
  endif()

  if (NOT TARGET Xenomai::Mercury AND XENOMAI_MERCURY_LIBRARY)
    add_library(Xenomai::Mercury INTERFACE IMPORTED)

    set_target_properties(Xenomai::Mercury PROPERTIES
      INTERFACE_COMPILE_DEFINITIONS "${__XENOMAI_COMPILE_DEFINITIONS}"
      INTERFACE_INCLUDE_DIRECTORIES "${__XENOMAI_INCLUDE_DIRS}"
      INTERFACE_LINK_LIBRARIES "${__XENOMAI_LINK_LIBRARIES}"
    )
  endif()

  set(_xenomai_libs)
  if(XENOMAI_CORE_TYPE_COBALT)
      set(_xenomai_libs Xenomai::Cobalt)
      if(NOT XENOMAI_SKIP_MODECHECK AND TARGET Xenomai::ModeChk)
        set(_xenomai_modecheck ${_xenomai_modecheck} Xenomai::ModeChk)
      endif()
      
    elseif(XENOMAI_CORE_TYPE_MERCURY)
      set(_xenomai_libs Xenomai::Mercury)
    endif()

  if (NOT TARGET Xenomai::Posix AND _xenomai_libs)
      add_library(Xenomai::Posix INTERFACE IMPORTED)
      set_target_properties(Xenomai::Posix PROPERTIES
          INTERFACE_COMPILE_DEFINITIONS "${__XENOMAI_COMPILE_POSIX_DEFINITIONS}"
          INTERFACE_LINK_LIBRARIES "${__XENOMAI_LINK_POSIX_LIBRARIES};${_xenomai_modecheck};${_xenomai_libs}"
      )
  endif()
  foreach(_extralib Vxworks Psos Alchemy Smokey)
    string(TOLOWER ${_extralib} _extralib_l)
    string(TOUPPER ${_extralib} _extralib_u)

    if (NOT TARGET Xenomai::${_extralib} AND XENOMAI_${_extralib_u}_LIBRARY)
      add_library(Xenomai::${_extralib} INTERFACE IMPORTED)

      set_target_properties(Xenomai::${_extralib} PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${XENOMAI_INCLUDE_DIR}/${_extralib_l}"
        INTERFACE_LINK_LIBRARIES "-l${_extralib_l};${XENOMAI_COPPERPLATE_LIBRARY};${_xenomai_modecheck};${_xenomai_libs}"
      )
    endif()
  endforeach(_extralib)
endif()

unset(_xenomai_libs)
unset(_extralib_l)
unset(_extralib_u)
unset(_extralib)
unset(__XENOMAI_LIBRARY_PATH)
unset(__XENOMAI_COMPILE_DEFINITIONS)
unset(__XENOMAI_INCLUDE_DIRS)
unset(__XENOMAI_LINK_LIBRARIES)
