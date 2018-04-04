# At LEAST 3.5 but newer is better
cmake_minimum_required(VERSION 3.5 FATAL_ERROR)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/../../../cmake/modules")

project(posix-cyclictest VERSION 0.92)

set(THREADS_PREFER_PTHREAD_FLAG true)
find_package(Threads REQUIRED)
find_package(Xenomai 3.0 REQUIRED)


add_executable(cyclictest
	cyclictest.c
	error.c
	rt-utils.c
)
target_link_libraries(cyclictest PRIVATE
	Xenomai::Bootstrap Xenomai::Posix Threads::Threads rt
)

target_compile_definitions(cyclictest PRIVATE
	-D_GNU_SOURCE
	VERSION_STRING="${PROJECT_VERSION}"
)

# Nice diagnostics
include(FeatureSummary)
feature_summary(WHAT ALL FATAL_ON_MISSING_REQUIRED_PACKAGES)
