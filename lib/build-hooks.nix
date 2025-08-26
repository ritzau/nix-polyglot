{ pkgs }:

{
  # Common build hooks that can be reused across language flakes

  # System information display hook
  systemInfoHook = ''
    echo
    echo System Info
    echo ===========
    ${pkgs.fastfetch}/bin/fastfetch
  '';

  # Build phase announcement hook
  buildPhaseHook = ''
    echo
    echo Building
    echo ========
  '';

  # Install phase announcement hook
  installPhaseHook = ''
    echo
    echo Installing
    echo ==========
  '';

  # Generic version hook that can be parameterized
  versionHook =
    { command, label }:
    ''
      echo -n "${label}: "
      ${command}
    '';
}
