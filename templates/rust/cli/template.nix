# Rust CLI Application Template
{
  name = "rust-cli";
  description = "Rust command-line application";

  # Template metadata
  language = "rust";
  category = "cli";

  # Files to create in the new project
  files = {
    "flake.nix" = ./flake.nix;
    "Cargo.toml" = ./Cargo.toml;
    "Cargo.lock" = ./Cargo.lock;
    "src/main.rs" = ./src/main.rs;
    ".envrc" = ./.envrc;
    ".gitignore" = ./.gitignore;
    ".editorconfig" = ./.editorconfig;
  };
}
