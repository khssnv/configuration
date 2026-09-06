{
  lib,
  pkgs,
  ...
}:

let
  cursorExtras =
    ps: with ps; {
      inherit git; # Git integrations.

      nix = [
        nixd # Nix language server.
        nixfmt # Nix formatter.
      ];

      python = [
        python3 # Python interpreter and debugger.
        pyright # Python language server.
        ruff # Python linter and formatter.
      ];

      rust = [
        rustc # Rust toolchain.
        cargo # Rust package manager.
        rustfmt # Rust formatter.
        clippy # Rust linter.
      ];

      js = [
        nodejs # JS/TS runtime, npm.
        typescript # TypeScript compiler.
        typescript-language-server # TypeScript language server.
        eslint # JS/TS linter.
        prettier # JS/TS formatter.
      ];
    };

  cursorFhs = pkgs.code-cursor.fhsWithPackages (
    ps: lib.flatten (builtins.attrValues (cursorExtras ps))
  );
in
{
  home.packages = [
    (pkgs.symlinkJoin {
      pname = "cursor-fhs-with-rust-src";
      inherit (cursorFhs) version;

      paths = [ cursorFhs ];
      nativeBuildInputs = [ pkgs.makeWrapper ];

      postBuild = ''
        rm "$out/bin/cursor"
        makeWrapper ${lib.getExe cursorFhs} "$out/bin/cursor" \
          --set-default RUST_SRC_PATH ${pkgs.rustPlatform.rustLibSrc} \
          --add-flags "--password-store=gnome-libsecret"
      '';

      inherit (cursorFhs) meta;

      passthru = {
        inherit (cursorFhs) executableName;
      };
    })
  ];
}
