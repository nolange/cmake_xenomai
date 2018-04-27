cmake_minimum_required(VERSION 3.0 FATAL_ERROR)
project(testxeno)

# Test with most annoying settings
add_compile_options(-std=c89 -Dinline=__inline__ -Wall -Wextra -pedantic -fno-pie )
set(CMAKE_EXE_LINKER_FLAGS -no-pie)
set(THREADS_PREFER_PTHREAD_FLAG True)
find_package(Threads REQUIRED)
set(TEST_FINDXENOMAI false)
if(TEST_FINDXENOMAI)
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake/modules")
endif()
find_package(xenomai REQUIRED)

function(debug_print_variables)
	get_cmake_property(_variableNames VARIABLES)
	foreach (_variableName ${_variableNames})
		message(STATUS "${_variableName}=${${_variableName}}")
	endforeach(_variableName)
endfunction(debug_print_variables)

# debug_print_variables()

# prefered variant for new projects
add_executable(default_exe
	"main_defined.c"
)

xenomai_target_bootstrap(default_exe
	SKINS posix
)

if(NOT CMAKE_VERSION VERSION_LESS 3.1)
# this one does not work with cmake 3.1 fallback
add_executable(wrap_main_exe
	"wrap_main_defined.c"
)

xenomai_target_bootstrap(wrap_main_exe
	MAIN SOURCE
	SKINS posix
)
endif()

#add_executable(wrap_precompiled_exe
#	"normal.c"
#)

#xenomai_target_bootstrap(wrap_precompiled_exe
#	MAIN PRECOMPILED
#	SKINS posix
#)


add_executable(wrap_precompiled_exe
	"normal.c"
)

xenomai_target_bootstrap(wrap_precompiled_exe
	MAIN PRECOMPILED
	MAIN_WRAP LINKER
	SKINS posix
)




#	if(XBS_MAIN AND NOT XBS_MAIN STREQUAL "NONE" AND NOT XBS_MAIN STREQUAL "SOURCE" AND NOT XBS_MAIN STREQUAL "PRECOMPILED")
#		set(_errors ${_errors} "MAIN only support the values NONE, SOURCE and PRECOMPILED")
#	endif()
#	if(MAIN_WRAP AND NOT MAIN_WRAP STREQUAL "NONE" AND NOT MAIN_WRAP STREQUAL "MACRO" AND NOT MAIN_WRAP STREQUAL "LINKER")

add_library(default_lib SHARED
	"test.c"
)

xenomai_target_bootstrap(default_lib
	SKINS posix
)
if (False)
add_executable(source_main
	"test.c"
)

xenomai_target_bootstrap(source_main
	MAIN SOURCE
	SKINS posix
)
endif()

add_executable(source_def_main
	"normal.c"
)

# this one does not work with cmake 3.1 fallback
xenomai_target_bootstrap(source_def_main
	MAIN SOURCE
	MAIN_WRAP MACRO
	SKINS posix
)
