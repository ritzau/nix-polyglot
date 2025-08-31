#include "hello.hpp"
#include <iostream>
#include <sstream>

namespace hello {
    
std::string get_greeting(const std::string& name) {
    return "Hello, " + name + " from C++! 🚀";
}

void print_count(int count) {
    std::cout << "Counting demonstration:\n";
    for (int i = 0; i < count; ++i) {
        std::cout << "Count: " << i << std::endl;
    }
}

std::string get_build_info() {
    std::ostringstream info;
    
#ifdef DEBUG_BUILD
    info << "🔧 Running DEBUG build (dev mode)";
#elif defined(RELEASE_BUILD)
    info << "🚀 Running RELEASE build (optimized)";
#else
    info << "📦 Standard build";
#endif

    info << "\nCompiler: ";
#ifdef __clang__
    info << "Clang " << __clang_major__ << "." << __clang_minor__;
#elif defined(__GNUC__)
    info << "GCC " << __GNUC__ << "." << __GNUC_MINOR__;
#else
    info << "Unknown compiler";
#endif

    info << "\nC++ Standard: " << __cplusplus;
    
    return info.str();
}

}