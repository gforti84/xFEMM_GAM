cmake_minimum_required (VERSION 2.8.8)
project (cfemm)

set(GCC_COVERAGE_COMPILE_FLAGS "-fpermissive")
set(GCC_WARNING_FLAGS "-Wall -Wextra")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${GCC_COVERAGE_COMPILE_FLAGS}" )
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${EXTRA_CMAKE_CXX_FLAGS} ${GCC_WARNING_FLAGS}")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${CMAKE_EXE_LINKER_FLAGS}")
set(CMAKE_SHARED_LIBRARY_LINK_CXX_FLAGS "${CMAKE_SHARED_LIBRARY_LINK_CXX_FLAGS} ${EXTRA_CMAKE_SHARED_LIBRARY_LINK_CXX_FLAGS}")

# set the output directories
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/bin)

add_subdirectory(fmesher)
add_subdirectory(fsolver)
add_subdirectory(fpproc)
add_subdirectory(hsolver)
add_subdirectory(hpproc)
