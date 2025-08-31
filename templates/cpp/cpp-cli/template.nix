# C++ CLI Template
{
  name = "cpp-cli";
  description = "C++ command-line application with CMake";

  # Template metadata
  language = "cpp";
  category = "cli";

  # Files to create in new project
  files = {
    "flake.nix" = ./flake.nix;
    "CMakeLists.txt" = ./CMakeLists.txt;
    "src/main.cpp" = ./src/main.cpp;
    "include/hello.hpp" = ./include/hello.hpp;
    "src/hello.cpp" = ./src/hello.cpp;
    "tests/test_hello.cpp" = ./tests/test_hello.cpp;
    "tests/CMakeLists.txt" = ./tests/CMakeLists.txt;
    ".envrc" = ./.envrc;
    ".gitignore" = ./.gitignore;
    ".editorconfig" = ./.editorconfig;
    ".clang-format" = ./.clang-format;
  };
}
