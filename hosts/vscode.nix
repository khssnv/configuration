{
  lib,
  pkgs,
  ...
}:

{
  programs.vscode = {
    enable = true;

    package =
      let
        vscodeExtras =
          ps: with ps; {
            inherit git; # GitLens, Git Graph and other Git integrations.

            csharp = [
              dotnet-sdk # ms-dotnettools.csharp language server, debugger and test runner.
            ];

            go = [
              delve # golang.go debugger (`dlv`).
              go # golang.go toolchain, formatter and test runner.
              go-tools # golang.go Staticcheck.
              gomodifytags # golang.go struct tag generator.
              gopls # golang.go language server.
              gotests # golang.go test generator.
              gotools # golang.go import tools, including `goimports`.
              impl # golang.go interface implementation generator.
            ];

            java = [
              jdk # vscjava.vscode-java-pack language server, debugger and build tools.
              gradle # vscjava.vscode-java-pack Gradle integration.
              maven # vscjava.vscode-java-pack Maven integration.
            ];

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
