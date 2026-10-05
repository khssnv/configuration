{
  lib,
  pkgs,
  pkgsUnstable,
  ...
}:

let
  python = pkgs.python3.withPackages (packages: [ packages.pathspec ]);
  copyLocal = pkgs.writeShellApplication {
    name = "wt-copy-local";
    runtimeInputs = [ pkgs.git ];
    text = ''
      exec ${lib.getExe python} ${../scripts/wt-copy-local/wt-copy-local.py} "$@"
    '';
  };
in
{
  # TODO: use `programs.worktrunk` for the package and shell integration once
  # available in the pinned Home Manager; keep config.toml sourced from dotfiles.
  home.packages = [
    # Stable lags behind upstream.
    pkgsUnstable.worktrunk
    copyLocal
  ];

  xdg.configFile."worktrunk/config.toml".source = ../dotfiles/worktrunk/config.toml;

  # Directory changes and completions.
  programs.zsh.initContent = ''
    eval "$(${lib.getExe pkgsUnstable.worktrunk} config shell init zsh)"
  '';
}
