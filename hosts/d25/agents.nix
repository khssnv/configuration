# Coding agents: the CLIs and their shared skill set.
#
# Both agents are configured through their config directories (`~/.claude` and
# `~/.codex`) rather than through CLI arguments, so the same settings apply to
# the CLIs installed here and to the VS Code extensions.

{
  inputs,
  pkgs,
  pkgsUnstable,
  ...
}:

let
  # Both agents accept the same value forms here (a directory, a file, or
  # inline text), so one set covers them. The attribute name becomes the skill
  # directory name, hence the `/name` command that invokes it.
  skills = {
    # Upstream ships a skill per directory; `caveman` itself is the compression
    # mode, the rest (caveman-commit, caveman-review, ...) are extras.
    caveman = "${inputs.caveman}/skills/caveman";
  };
in
{
  home.packages = [
    pkgs.pi-coding-agent # `pi`, the agent little-coder is built on.
  ];

  programs = {
    claude-code = {
      enable = true;

      inherit skills;
    };

    codex = {
      enable = true;
      package = pkgsUnstable.codex;

      inherit skills;
    };
  };
}
