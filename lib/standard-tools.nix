{ pkgs }:

let
  # General development tools available in all environments
  generalTools = with pkgs; [
    # File and directory utilities
    tree
    bat # Better cat with syntax highlighting

    # System monitoring and info
    bottom # Better top/htop
    fastfetch # System information display

    # Data processing
    jq # JSON processor

    # Git utilities (if not already available)
    git

    # Text processing
    ripgrep # Fast grep replacement
    fd # Fast find replacement
  ];

  # Common build/development tools that many languages can benefit from
  commonBuildTools = with pkgs; [
    # Output formatting for consistent build experience
    figlet # ASCII art text for build phases

    # Build utilities and task runners
    gnumake # Make for languages that use it
    just # Command runner - organizational standard interface
    pkg-config # Package configuration

    # Archive/compression tools
    unzip
    gzip
  ];

  # Organizational security and quality tools
  # These should be available in all development environments
  securityTools = with pkgs; [
    # Security scanning (add your org's preferred tools)
    # Example: sonarqube-scanner, snyk, etc.
  ];

  # Shell customization tools
  shellTools = with pkgs; [
    # Shell improvements
    zsh
    bash

    # Terminal multiplexing
    tmux

    # Command history and search
    fzf # Fuzzy finder
  ];

  # Documentation and help tools
  docTools = with pkgs; [
    # Documentation generators and viewers
    pandoc # Universal document converter

    # Man page utilities
    man-pages
  ];

in
# Organizational standard tools - single source of truth
  # This ensures consistent tooling across all language environments
{
  # Expose individual tool categories
  inherit
    generalTools
    commonBuildTools
    securityTools
    shellTools
    docTools
    ;

  # Combine all standard tools that should be in every dev environment
  getAllStandardTools = generalTools ++ commonBuildTools ++ securityTools ++ shellTools ++ docTools;

  # Minimal set for lightweight environments
  getMinimalTools = generalTools ++ [ pkgs.figlet ]; # At minimum, keep the build formatting
}
