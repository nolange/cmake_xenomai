# At LEAST 3.5 but newer is better
cmake_minimum_required(VERSION 3.0 FATAL_ERROR)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/../../../cmake/modules")

project(cross-link VERSION 0.1)

#set(THREADS_PREFER_PTHREAD_FLAG true)
find_package(Xenomai 3.0 REQUIRED)

add_executable(cross-link
	cross-link.c
)

target_link_libraries(cross-link PRIVATE
	Xenomai::Alchemy Xenomai::Cobalt rt
)
target_compile_definitions(cross-link PRIVATE
	_GNU_SOURCE
)
