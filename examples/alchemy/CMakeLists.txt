# At LEAST 3.5 but newer is better
cmake_minimum_required(VERSION 3.5 FATAL_ERROR)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/modules")

project(altency VERSION 0.1)

set(THREADS_PREFER_PTHREAD_FLAG true)
find_package(Threads REQUIRED)
find_package(Xenomai 3.0 REQUIRED)

add_executable(altency
	altency.c
)

target_link_libraries(altency PRIVATE
	Xenomai::Alchemy
)

# Nice diagnostics
include(FeatureSummary)
feature_summary(WHAT ALL FATAL_ON_MISSING_REQUIRED_PACKAGES)