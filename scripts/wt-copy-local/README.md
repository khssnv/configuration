# wt-copy-local

Extends Worktrunk's [ignored-file copying](https://worktrunk.dev/step/#wt-step-copy-ignored)
with tracked changes and untracked files; the [global hooks](../../dotfiles/worktrunk/config.toml)
copy from the primary worktree when creating a worktree.

Commit `.worktreeinclude` at the primary worktree root. Positive gitignore-style
patterns include paths, `!` excludes them, and `#` starts a comment; without the
file, neither step copies anything.

```gitignore
.gitignore
docs/
node_modules/
!docs/drafts/
```

Requires Python 3.10+, pathspec and Git, supplied by the [Nix module](../../hosts/worktrunk.nix).
See `--help` for behavior and limits, and the [command reference](../../docs/worktrunk.md) for usage.

```sh
wt-copy-local --help
# From the repository root, with pathspec installed in this interpreter
python3 -m unittest discover -s scripts/wt-copy-local
```
