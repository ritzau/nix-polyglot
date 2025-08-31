cmake_minimum_required(VERSION 3.20)
project(hello-cpp VERSION 0.1.0)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Include directories
include_directories(include)

# Source files
set(SOURCES
    src/hello.cpp
)

set(HEADERS
    include/hello.hpp
)

# Create library
add_library(hello_lib ${SOURCES} ${HEADERS})
target_include_directories(hello_lib PUBLIC include)

# Create executable
add_executable(hello-cpp src/main.cpp)
target_link_libraries(hello-cpp hello_lib)

# Enable testing
enable_testing()

# Add tests subdirectory
add_subdirectory(tests)

# Install target
install(TARGETS hello-cpp DESTINATION bin)