# Go CLI Application Template
{
  name = "go-cli";
  language = "go";
  description = "Go CLI application";

  files = {
    "flake.nix" = ./flake.nix;
    ".envrc" = ./.envrc;
    ".gitignore" = ./.gitignore;
    ".editorconfig" = ./.editorconfig;
    "main.go" = ./main.go;
    "main_test.go" = ./main_test.go;
    "go.mod" = ./go.mod;
  };
}
