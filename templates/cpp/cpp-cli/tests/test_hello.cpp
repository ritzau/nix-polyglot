#include "hello.hpp"
#include <iostream>
#include <cassert>
#include <string>

// Simple test framework
int test_count = 0;
int test_passed = 0;

void test_assert(bool condition, const std::string& test_name) {
    test_count++;
    if (condition) {
        test_passed++;
        std::cout << "✅ PASS: " << test_name << std::endl;
    } else {
        std::cout << "❌ FAIL: " << test_name << std::endl;
    }
}

int main() {
    std::cout << "Running C++ tests...\n" << std::endl;
    
    // Test get_greeting function
    {
        std::string greeting = hello::get_greeting("Test");
        test_assert(greeting.find("Hello, Test") != std::string::npos, 
                   "get_greeting should contain 'Hello, Test'");
        test_assert(greeting.find("C++") != std::string::npos, 
                   "get_greeting should contain 'C++'");
    }
    
    // Test default greeting
    {
        std::string default_greeting = hello::get_greeting();
        test_assert(default_greeting.find("World") != std::string::npos,
                   "default greeting should contain 'World'");
    }
    
    // Test build info
    {
        std::string build_info = hello::get_build_info();
        test_assert(!build_info.empty(), "build_info should not be empty");
        test_assert(build_info.find("build") != std::string::npos,
                   "build_info should contain 'build'");
    }
    
    // Results
    std::cout << "\n📊 Test Results:" << std::endl;
    std::cout << "Tests run: " << test_count << std::endl;
    std::cout << "Tests passed: " << test_passed << std::endl;
    std::cout << "Tests failed: " << (test_count - test_passed) << std::endl;
    
    if (test_passed == test_count) {
        std::cout << "🎉 All tests passed!" << std::endl;
        return 0;
    } else {
        std::cout << "💥 Some tests failed!" << std::endl;
        return 1;
    }
}