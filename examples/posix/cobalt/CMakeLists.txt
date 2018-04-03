# At LEAST 3.5 but newer is better
cmake_minimum_required(VERSION 3.5 FATAL_ERROR)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/../../../cmake/modules")

project(posix-cobalt-demos VERSION 0.1)

set(THREADS_PREFER_PTHREAD_FLAG true)
find_package(Threads REQUIRED)
find_package(Xenomai 3.0 REQUIRED)

foreach(tool bufp-label bufp-readwrite can-rtt eth_p_all gpiopwm iddp-label iddp-sendrecv xddp-echo xddp-label xddp-stream)
 	add_executable(${tool}
		${tool}.c
	)
	target_link_libraries(${tool} PRIVATE
		Xenomai::Cobalt Threads::Threads rt
	)
	target_compile_definitions(${tool} PRIVATE
		_GNU_SOURCE
	)
endforeach(tool)

target_include_directories(gpiopwm PRIVATE
	"gpiopwm"
)


# Nice diagnostics
include(FeatureSummary)
feature_summary(WHAT ALL FATAL_ON_MISSING_REQUIRED_PACKAGES)
