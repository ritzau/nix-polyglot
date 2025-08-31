# Test executable
add_executable(test_hello test_hello.cpp)
target_link_libraries(test_hello hello_lib)

# Register test
add_test(NAME hello_tests COMMAND test_hello)