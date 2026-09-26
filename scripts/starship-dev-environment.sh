#!/usr/bin/env bash
# Print "project:tool" inside a Nix or devenv shell, nothing otherwise.

if [[ -n ${DEVENV_ROOT-} ]]; then
  tool=devenv
elif [[ -n ${IN_NIX_SHELL-} ]]; then
  tool=nix
else
  exit 0
fi

# mkShell and devenv export the shell name; nix develop appends "-env".
project=${name-}
project=${project%-env}

# Default names say nothing about the project, use its directory instead.
case $project in
  "" | shell | nix-shell | devenv-shell)
    root=${DEVENV_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}
    project=${root##*/}
    ;;
esac

printf '%s:%s\n' "$project" "$tool"
