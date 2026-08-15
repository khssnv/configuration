{
  pkgs,
  lib,
  ...
}:

{
  programs.vscode = {
    enable = true;

    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        jnoortheen.nix-ide
      ];

      userSettings."window.autoDetectColorScheme" = true;
    };

    package =
      let
        vscodeExtras =
          ps: with ps; {
            inherit git; # GitLens, Git Graph and other Git integrations.

            nix = [
              nixd # jnoortheen.nix-ide language server.
              nixfmt # jnoortheen.nix-ide formatter.
            ];

            python = [
              python3 # ms-python.python interpreter and debugger.
              pyright # ms-pyright.pyright language server.
              ruff # charliermarsh.ruff linter and formatter.
            ];

            rust = [
              rustc # rust-lang.rust-analyzer toolchain.
              cargo # rust-lang.rust-analyzer toolchain, `cargo` commands.
              rustfmt # rust-lang.rust-analyzer formatter, `cargo fmt`.
              clippy # `cargo clippy` linter.
            ];

            js = [
              nodejs # JS/TS runtime, npm.
              typescript # Built-in TypeScript/JavaScript language features.
              typescript-language-server # Built-in TypeScript/JavaScript language features.
              eslint # dbaeumer.vscode-eslint linter.
              prettier # esbenp.prettier-vscode formatter.
            ];
          };

        vscodeFhs = pkgs.vscode.fhsWithPackages (ps: lib.flatten (builtins.attrValues (vscodeExtras ps)));
      in
      pkgs.symlinkJoin {
        pname = "vscode-fhs-with-rust-src";
        inherit (vscodeFhs) version;

        paths = [ vscodeFhs ];
        nativeBuildInputs = [ pkgs.makeWrapper ];

        postBuild = ''
          rm "$out/bin/code"
          makeWrapper ${lib.getExe vscodeFhs} "$out/bin/code" \
            --set-default RUST_SRC_PATH ${pkgs.rustPlatform.rustLibSrc} \
            --add-flags "--password-store=gnome-libsecret"
        '';

        inherit (vscodeFhs) meta;

        passthru = {
          inherit (vscodeFhs) executableName;
        };
      };
  };
}
