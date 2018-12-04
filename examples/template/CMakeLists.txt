# define version requirements
cmake_minimum_required( VERSION 3.1 )

project(test)

option(CMAKE_USE_XENOMAI "Use Xenomai libraries" ON)

set(THREADS_PREFER_PTHREAD_FLAG true)
find_package(Threads REQUIRED)

if(CMAKE_USE_XENOMAI)
  find_package(Xenomai 3.0 REQUIRED)#
  if(TARGET Xenomai::cobalt)
    set(USE_COBALT True)
  endif()
endif()


add_executable(test)

if(CMAKE_USE_XENOMAI)
  xenomai_target_bootstrap(test
  	SKINS posix)
endif()

target_link_libraries(test PRIVATE
	Threads::Threads -lrt
)

add_subdirectory(src)

include(FeatureSummary)
feature_summary(WHAT ALL FATAL_ON_MISSING_REQUIRED_PACKAGES)
