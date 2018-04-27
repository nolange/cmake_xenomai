# At LEAST 3.5 but newer is better
cmake_minimum_required(VERSION 3.0 FATAL_ERROR)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/../../../cmake/modules")

project(posix-cyclictest VERSION 0.92)

set(THREADS_PREFER_PTHREAD_FLAG true)
find_package(Threads REQUIRED)
find_package(Xenomai 3.0 REQUIRED)

# Hack in support for CMake 3.0
if(CMAKE_VERSION VERSION_LESS "3.1" AND CMAKE_THREAD_LIBS_INIT)
	add_library(Threads::Threads INTERFACE IMPORTED)
	set_property(TARGET Threads::Threads PROPERTY INTERFACE_LINK_LIBRARIES "${CMAKE_THREAD_LIBS_INIT}")
endif()

# broken too
#set(_XENOMAI_BOOTSTRAP_SOURCE)
#if(CMAKE_VERSION VERSION_LESS "3.1" AND XENOMAI_BOOTSTRAP_WRAP_SRC)
#	set(_XENOMAI_BOOTSTRAP_SOURCE ${XENOMAI_BOOTSTRAP_WRAP_SRC})
#endif()

add_executable(cyclictest
	cyclictest.c
	error.c
	rt-utils.c
	${_XENOMAI_BOOTSTRAP_SOURCE}
)
target_link_libraries(cyclictest PRIVATE
	Xenomai::Posix Threads::Threads rt
)
# Xenomai::Bootstrap
if(CMAKE_VERSION VERSION_LESS "3.1")
target_link_libraries(cyclictest PRIVATE
	Xenomai::Bootstrap
)
endif()

# broken for < 3.1 currently !
if(NOT CMAKE_VERSION VERSION_LESS "3.1")
xenomai_target_bootstrap(cyclictest
	)
endif()

target_link_libraries(cyclictest PRIVATE
	-Wl,-Map=$<TARGET_PROPERTY:NAME>.map,--cref,--enable-new-dtags,-z,relro,-z,now
)

target_compile_definitions(cyclictest PRIVATE
	-D_GNU_SOURCE
	VERSION_STRING="${PROJECT_VERSION}"
)

# Nice diagnostics
include(FeatureSummary)
feature_summary(WHAT ALL FATAL_ON_MISSING_REQUIRED_PACKAGES)
