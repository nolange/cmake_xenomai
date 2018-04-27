cmake_minimum_required(VERSION 3.0 FATAL_ERROR)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/modules")

project(altency VERSION 0.1)

set(THREADS_PREFER_PTHREAD_FLAG true)
find_package(Threads REQUIRED)
find_package(Xenomai 3.0 REQUIRED)

# Hack in support for CMake 3.0
if(CMAKE_VERSION VERSION_LESS "3.1" AND CMAKE_THREAD_LIBS_INIT)
	add_library(Threads::Threads INTERFACE IMPORTED)
	set_property(TARGET Threads::Threads PROPERTY INTERFACE_LINK_LIBRARIES "${CMAKE_THREAD_LIBS_INIT}")
endif()

add_executable(altency
	altency.c
)

target_link_libraries(altency PRIVATE
	-Wl,-Map=$<TARGET_PROPERTY:NAME>.map,--cref,--enable-new-dtags,-z,relro,-z,now
)

target_link_libraries(altency PRIVATE
	Xenomai::Alchemy
)

# Nice diagnostics
include(FeatureSummary)
feature_summary(WHAT ALL FATAL_ON_MISSING_REQUIRED_PACKAGES)
