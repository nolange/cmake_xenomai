# we need INTERFACE libraries introduced in 3.0
cmake_minimum_required(VERSION 3.0)
project(Xenomai)
include(GNUInstallDirs)

# set(PROVIDE_STATIC true)
set(_staticlibs -static)

set(_XENOMAI_CMAKEDIR "${CMAKE_INSTALL_LIBDIR}/cmake/xenomai")
# set(XENOMAI_CORE_TYPE_COBALT true)
# set(XENOMAI_CORE_TYPE_MERCURY true)
set(corelib)

find_package(Threads REQUIRED)

# pnly skins which have a library behind it, Posix does not!
set(_skins Vxworks Psos Alchemy Smokey)

set(_modechk)
if(XENOMAI_CORE_TYPE_COBALT)
  set(XENOMAI_CORE_TYPE Cobalt)
  set(corelib ${corelib} Cobalt)

  set(_modechk Modechk)
endif()
if(XENOMAI_CORE_TYPE_MERCURY)
  set(XENOMAI_CORE_TYPE Mercury)
  set(corelib ${corelib} Mercury)
endif()

string(TOLOWER ${XENOMAI_CORE_TYPE} _corename)
string(TOUPPER ${XENOMAI_CORE_TYPE} _upcorename)

# Xenomai core - cobalt or mercury
add_library(${_corename} SHARED test.c)
target_link_libraries(${_corename} PUBLIC Threads::Threads -lrt)
target_compile_definitions(${_corename} PUBLIC __${_upcorename}__)

target_include_directories(${_corename}
  PUBLIC "${CMAKE_INSTALL_FULL_INCLUDEDIR}/${_corename}"
         "${CMAKE_INSTALL_FULL_INCLUDEDIR}")

# modechek library
if(_modechk)
  string(TOLOWER ${_modechk} _lbname)
  add_library(${_lbname} SHARED test.c)
  target_link_libraries(${_lbname}
    INTERFACE "-Wl,@${CMAKE_INSTALL_FULL_LIBDIR}/modechk.wrappers")
  # push the dependent libraries to the far right side
  target_link_libraries(${_lbname} PUBLIC Threads::Threads -lrt)
endif()

# posix skin, does not have a extra library but might have wrappers
add_library(posix INTERFACE)

if(XENOMAI_CORE_TYPE_COBALT)
  target_compile_definitions(posix INTERFACE __COBALT_WRAP__)
  target_link_libraries(posix
    INTERFACE "-Wl,@${CMAKE_INSTALL_FULL_LIBDIR}/cobalt.wrappers" ${_corename})

else()
  target_link_libraries(posix INTERFACE ${_corename})
endif()

# copperplate, lower emulation layer for RT skins
add_library(copperplate SHARED test.c)
target_link_libraries(copperplate PUBLIC ${_corename})

# emulation skins, based on copperplate
foreach(_skin ${_skins})
  string(TOLOWER ${_skin} _lbname)
  add_library(${_lbname} SHARED test.c)
  target_include_directories(${_lbname}
    PUBLIC "${CMAKE_INSTALL_FULL_INCLUDEDIR}/${_lbname}")

  target_link_libraries(${_lbname} PUBLIC copperplate)
endforeach()

# legacy_bootstrap support
add_library(legacy_bootstrap INTERFACE)

target_link_libraries(legacy_bootstrap
  INTERFACE
    "$<$<STREQUAL:$<TARGET_PROPERTY:TYPE>,SHARED_LIBRARY>:${CMAKE_INSTALL_FULL_LIBDIR}/xenomai/bootstrap-pic.o>"
    "$<$<STREQUAL:$<TARGET_PROPERTY:TYPE>,EXECUTABLE>:${CMAKE_INSTALL_FULL_LIBDIR}/xenomai/bootstrap.o>"
  )

add_library(legacy_bootstrap_wrap INTERFACE)
target_link_libraries(legacy_bootstrap_wrap
  INTERFACE
    "$<$<STREQUAL:$<TARGET_PROPERTY:TYPE>,EXECUTABLE>:-Wl,--wrap=main,--dynamic-list=${CMAKE_INSTALL_FULL_LIBDIR}/dynlist.ld>"
  )

foreach(_library ${corelib} ${_modechk} legacy_bootstrap legacy_bootstrap_wrap
                 Posix Copperplate ${_skins})
  string(TOLOWER ${_library} _lbname)

  install(TARGETS ${_lbname}
          EXPORT xenomai-targets
          ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}" COMPONENT ${_library}
          LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}" COMPONENT ${_library}
          PUBLIC_HEADER DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}"
                        COMPONENT ${_library}
          RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}" COMPONENT ${_library})
  # This is for Windows
  if(PROVIDE_STATIC)
    install(TARGETS ${_lbname}${_staticlibs}
            EXPORT xenomai-targets
            ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}" COMPONENT ${_library}
            LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}" COMPONENT ${_library}
            PUBLIC_HEADER DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}"
                          COMPONENT ${_library}
            RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}" COMPONENT ${_library})
    # This is for Windows
  endif()
  unset(_lbname)
endforeach()

install(EXPORT xenomai-targets
        DESTINATION "${_XENOMAI_CMAKEDIR}"
        NAMESPACE Xenomai::
        COMPONENT xenomai-export)

include(CMakePackageConfigHelpers)
write_basic_package_version_file(${CMAKE_CURRENT_BINARY_DIR}/xenomai-config-version.cmake
  VERSION "@CMAKE_VERSION_CODE@"
  COMPATIBILITY AnyNewerVersion)
configure_package_config_file(xenomai-config.cmake.in
                              ${CMAKE_CURRENT_BINARY_DIR}/xenomai-config.cmake
                              INSTALL_DESTINATION
                              "${_XENOMAI_CMAKEDIR}")

install(FILES ${CMAKE_CURRENT_BINARY_DIR}/xenomai-config-version.cmake
              ${CMAKE_CURRENT_BINARY_DIR}/xenomai-config.cmake
              xenomai-macros.cmake
        DESTINATION "${_XENOMAI_CMAKEDIR}")
