# Python Console Application Template
{
  name = "python-console";
  description = "Python console application with poetry";

  # Template metadata
  language = "python";
  category = "console";

  # Files to create in the new project
  files = {
    "flake.nix" = ./flake.nix;
    "pyproject.toml" = ./pyproject.toml;
    "myapp/__init__.py" = ./myapp/__init__.py;
    "myapp/main.py" = ./myapp/main.py;
    "tests/__init__.py" = ./tests/__init__.py;
    "tests/test_main.py" = ./tests/test_main.py;
    "justfile" = ./justfile;
    ".gitignore" = ./.gitignore;
    ".editorconfig" = ./.editorconfig;
    "README.md" = ./README.md;
  };
}
