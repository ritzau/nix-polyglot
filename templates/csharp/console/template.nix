# C# Console Application Template
{
  name = "csharp-console";
  description = "C# console application with .NET 8";

  # Template metadata
  language = "csharp";
  category = "console";

  # Files to create in the new project
  files = {
    "flake.nix" = ./flake.nix;
    "MyApp.csproj" = ./MyApp.csproj;
    "Program.cs" = ./Program.cs;
    "justfile" = ./justfile;
    ".gitignore" = ./.gitignore;
    ".editorconfig" = ./.editorconfig;
  };
}
