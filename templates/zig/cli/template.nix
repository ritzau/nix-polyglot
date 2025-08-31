# Zig CLI Application Template
{
  name = "zig-cli";
  language = "zig";
  description = "Zig CLI application";

  files = {
    "flake.nix" = ./flake.nix;
    ".envrc" = ./.envrc;
    ".gitignore" = ./.gitignore;
    ".editorconfig" = ./.editorconfig;
    "build.zig" = ./build.zig;
    "src/main.zig" = ./src/main.zig;
  };
}
