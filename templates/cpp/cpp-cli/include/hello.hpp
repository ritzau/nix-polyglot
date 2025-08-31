#pragma once

#include <string>

namespace hello {
    /**
     * @brief Get a greeting message
     * @param name The name to greet
     * @return A personalized greeting
     */
    std::string get_greeting(const std::string& name = "World");
    
    /**
     * @brief Print a counting sequence for demonstration
     * @param count Number of iterations to count
     */
    void print_count(int count = 5);
    
    /**
     * @brief Get build information
     * @return Build type and compiler information
     */
    std::string get_build_info();
}