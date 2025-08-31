#include "hello.hpp"
#include <iostream>

int main() {
    std::cout << hello::get_greeting("World") << std::endl;
    std::cout << "This is a C++ console application created with nix-polyglot.\n" << std::endl;
    
    std::cout << hello::get_build_info() << "\n" << std::endl;
    
    hello::print_count(5);
    
    return 0;
}