# Nim CLI Application Template
{
  name = "nim-cli";
  language = "nim";
  description = "Nim CLI application";

  files = {
    "flake.nix" = ./flake.nix;
    ".envrc" = ./.envrc;
    ".gitignore" = ./.gitignore;
    ".editorconfig" = ./.editorconfig;
    "config.nims" = ./config.nims;
    "nim_project.nimble" = ./nim_project.nimble;
    "src/main.nim" = ./src/main.nim;
    "tests/test_main.nim" = ./tests/test_main.nim;
  };
}
