# Starship prompt replicating Oh My Zsh's `ys` theme, plus a "(project:tool)"
# indicator for Nix and devenv shells. Home Manager also hooks it into Bash,
# so interactive `nix develop` sessions get the same prompt.
{ lib, pkgs, ... }:

let
  # Starship's nix_shell module shows only the raw `name` ("nix-shell-env" for
  # an unnamed mkShell) and does not recognize devenv, hence the helper.
  # `nix shell` exports no marker and is not shown.
  devEnvironment = pkgs.writeShellApplication {
    name = "starship-dev-environment";
    runtimeInputs = [ pkgs.git ];
    text = builtins.readFile ../scripts/starship-dev-environment.sh;
  };
  promptShell = [
    "${pkgs.bash}/bin/bash"
    "--noprofile"
    "--norc"
  ];
  gitStatus = "${lib.getExe pkgs.git} --no-optional-locks status --porcelain";
in
{
  programs.starship = {
    enable = true;
    settings = {
      # Explicit modules keep runtime versions and icons out of the prompt.
      format = lib.concatStrings [
        "[#](bold blue) $username @ $hostname in $directory"
        "$git_branch$git_commit"
        "\${custom.git_dirty}\${custom.git_clean}"
        "$time$status$line_break"
        "\${custom.dev_environment}$character"
      ];

      username = {
        show_always = true;
        format = "[$user]($style)";
        style_user = "cyan";
        style_root = "black bg:yellow";
      };
      hostname = {
        ssh_only = false;
        format = "[$hostname](green)";
      };
      directory = {
        format = "[$path](bold yellow)";
        truncation_length = 0;
        truncate_to_repo = false;
      };
      git_branch = {
        format = " on [git:](blue)[$branch](cyan)";
        only_attached = true;
      };
      git_commit.format = " on [git:](blue)[$hash](cyan)";
      time = {
        disabled = false;
        format = " \\[$time\\]";
        time_format = "%H:%M:%S";
      };
      status = {
        disabled = false;
        format = " [C:$status](red)";
      };
      character = {
        success_symbol = "[\\$](bold red)";
        error_symbol = "[\\$](bold red)";
      };

      custom = {
        # A single x/o, as in ys, even when several kinds of change coexist.
        git_dirty = {
          shell = promptShell;
          require_repo = true;
          when = ''changes="$(${gitStatus} 2>/dev/null)" && test -n "$changes"'';
          format = " [x](red)";
        };
        git_clean = {
          shell = promptShell;
          require_repo = true;
          when = ''changes="$(${gitStatus} 2>/dev/null)" && test -z "$changes"'';
          format = " [o](green)";
        };
        dev_environment = {
          shell = promptShell;
          when = true;
          command = lib.getExe devEnvironment;
          format = "([\\($output\\)](bold green) )";
        };
      };
    };
  };
}
