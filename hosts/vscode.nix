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
            cpp = [
              clang-tools # C/C++ formatting and clangd tools.
              cmake # ms-vscode.cmake-tools.
              gcc # C/C++ compiler.
              gdb # C/C++ debugger.
              gnumake # ms-vscode.makefile-tools.
              lldb # vadimcn.vscode-lldb.
              ninja # CMake generator.
              pkg-config # Native build metadata lookup.
            ];

            csharp = [
              dotnet-sdk # ms-dotnettools.csharp language server, debugger and test runner.
            ];

            docker = [
              docker-client # ms-azuretools.vscode-docker Docker CLI.
              docker-compose # ms-azuretools.vscode-docker Compose commands.
              docker-buildx # ms-azuretools.vscode-docker Buildx commands.
            ];

            inherit git; # GitLens, Git Graph and other Git integrations.

            go = [
              delve # golang.go debugger (`dlv`).
              go # golang.go toolchain, formatter and test runner.
              go-tools # golang.go Staticcheck.
              gomodifytags # golang.go struct tag generator.
              gopls # golang.go language server.
              gotests # golang.go test generator.
              gotools # golang.go import tools, including `goimports`.
              impl # golang.go interface implementation generator.
              templ # a-h.templ language server.
            ];

            haskell = [
              cabal-install # haskell.haskell build tool.
              ghc # haskell.haskell compiler.
              haskell-language-server # haskell.haskell language server.
              hlint # haskell.haskell diagnostics.
              stack # haskell.haskell build tool.
            ];

            infra = [
              actionlint # github.vscode-github-actions workflow validation.
              ansible # redhat.ansible `ansible-playbook`.
              ansible-builder # redhat.ansible content creator tools.
              ansible-lint # redhat.ansible validation.
              ansible-navigator # redhat.ansible navigator command.
              aws-sam-cli # amazonwebservices.aws-toolkit-vscode SAM commands.
              awscli2 # amazonwebservices.aws-toolkit-vscode AWS CLI.
              kubectl # ms-kubernetes-tools.vscode-kubernetes-tools.
              kubernetes-helm # ms-kubernetes-tools.vscode-kubernetes-tools.
              kustomize # Kubernetes manifests.
              minikube # ms-kubernetes-tools.vscode-kubernetes-tools.
              terraform # hashicorp.terraform CLI commands.
              vagrant # bbenoist.vagrant.
              yamllint # redhat.ansible and YAML diagnostics.
            ];

            java = [
              jdk # vscjava.vscode-java-pack language server, debugger and build tools.
              gradle # vscjava.vscode-java-pack Gradle integration.
              maven # vscjava.vscode-java-pack Maven integration.
            ];

            javascript = [
              nodejs # JS/TS runtime, npm.
              typescript # Built-in TypeScript/JavaScript language features.
              typescript-language-server # Built-in TypeScript/JavaScript language features.
              eslint # dbaeumer.vscode-eslint linter.
              prettier # esbenp.prettier-vscode formatter.
            ];

            kotlin = [
              kotlin # fwcd.kotlin toolchain.
              kotlin-language-server # fwcd.kotlin language server.
              ktlint # Kotlin linting and formatting.
            ];

            nix = [
              nixd # jnoortheen.nix-ide language server.
              nixfmt # jnoortheen.nix-ide formatter.
            ];

            python = [
              python3 # ms-python.python interpreter and debugger.
              pyright # ms-pyright.pyright language server.
              ruff # charliermarsh.ruff linter and formatter.
              black # ms-python.black-formatter.
              isort # ms-python.isort.
              jupyter # ms-toolsai.jupyter.
              pipenv # ms-python.python environment discovery.
              pixi # ms-python.python environment discovery.
              poetry # ms-python.python environment discovery.
              python3Packages.autopep8 # ms-python.autopep8.
              python3Packages.cfn-lint # amazonwebservices.aws-toolkit-vscode CloudFormation linting.
              python3Packages.ipykernel # ms-toolsai.jupyter kernels.
              uv # ms-python.python environment discovery.
            ];

            ruby = [
              ruby # Shopify.ruby-lsp runtime.
              rubyPackages.ruby-lsp # Shopify.ruby-lsp server gem.
            ];

            rust = [
              rustc # rust-lang.rust-analyzer toolchain.
              cargo # rust-lang.rust-analyzer toolchain, `cargo` commands.
              rustfmt # rust-lang.rust-analyzer formatter, `cargo fmt`.
              clippy # `cargo clippy` linter.
            ];

            shell = [
              bash-language-server # Shell scripts language server.
              shellcheck # Shell scripts diagnostics.
              shfmt # foxundermoon.shell-format formatter.
            ];

            tlaplus = [
              tlaplus # tlaplus.vscode-ide TLC tools.
              tlaps # tlaplus.vscode-ide proof tools.
            ];

            zig = [
              zig # ziglang.vscode-zig toolchain.
              zls # ziglang.vscode-zig language server.
            ];

            misc = [
              claude-code # anthropic.claude-code CLI integration.
              chromium # yzane.markdown-pdf Chromium runtime.
              graphviz # tintinweb.graphviz-interactive-preview and PlantUML diagrams.
              openscad # Leathong.openscad-language-support and URDF previews.
              openssh # ms-vscode-remote.remote-ssh `ssh`.
              plantuml # jebbs.plantuml and mebrahtom.plantumlpreviewer.
              protobuf # Protocol Buffers compiler.
              protolint # plex.vscode-protolint.
              sqlite # alexcvzz.vscode-sqlite fallback CLI.
              tex-fmt # james-yu.latex-workshop optional formatter.
              (texlive.combine {
                inherit (texlive)
                  scheme-small
                  chktex
                  lacheck
                  latexindent
                  latexmk
                  synctex
                  texcount
                  texdoc
                  ;
              }) # james-yu.latex-workshop toolchain.
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
