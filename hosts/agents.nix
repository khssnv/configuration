# Coding agents: the CLIs, shared skills, and MCP servers.
#
# Home Manager manages the agents' context and skills in their config
# directories. Shared MCP servers use Codex's system config and a Claude Code
# plugin.

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
    pkgsUnstable.terraform-mcp-server # Stable still packages 0.5.2.

    # Token usage and cost reports from the agents' local session logs, which
    # the VS Code extensions share with the CLIs. Absent from stable.
    #
    # Main commans:
    # ccusage daily --by-agent
    # ccusage monthly
    # ccusage session
    # ccusage claude blocks
    pkgsUnstable.ccusage
  ];

  programs = {
    mcp = {
      enable = true;
      servers.terraform.command = "${pkgsUnstable.terraform-mcp-server}/bin/terraform-mcp-server";
    };

    claude-code = {
      enable = true;
      enableMcpIntegration = true;
      package = pkgsUnstable.claude-code;
      context = ../dotfiles/agents.md;

      inherit skills;
    };

    codex = {
      enable = true;
      package = pkgsUnstable.codex;
      context = ../dotfiles/agents.md;

      inherit skills;
    };
  };
}
