# Worktrunk

[Worktrunk](https://worktrunk.dev/switch/) manages Git worktrees by branch name.

The global [config](../dotfiles/worktrunk/config.toml) places worktrees in
`../<repo>.worktrees/<sanitized-branch>`; `pre-start` hooks copy local and ignored
files selected by `.worktreeinclude` from the primary worktree
([customization](../scripts/wt-copy-local/README.md)).

## Everyday commands

```sh
wt list                                  # Worktrees and status
wt list --branches                       # Include branches without worktrees
wt switch                                # Interactive picker
wt switch task                           # Existing branch; create worktree if needed
wt switch -                              # Previous worktree
wt switch '^'                            # Default branch worktree
wt step diff                             # All changes since branching
wt merge                                 # Commit, squash, rebase, merge; remove worktree
wt remove task                           # Remove worktree; delete branch if merged
wt remove task --no-delete-branch         # Remove worktree, keep branch
```

## With local copying

```sh
# From the primary worktree; use its HEAD to avoid patch conflicts
wt switch --create task --base=@
```

## Without customization

```sh
# Skip all hooks, including copying; keep the configured worktree path
wt switch --create clean-task --base=@ --no-hooks

# Use stock paths and skip all hooks for this command
wt --config /dev/null switch --create stock-task --base=@ --no-hooks
```

## [Copy manually](https://worktrunk.dev/step/#wt-step-copy-ignored)

```sh
# Source root and existing clean destination, e.g. clean-task above
wt-copy-local --dry-run /path/to/repo /path/to/repo.worktrees/clean-task
wt step copy-ignored --from /path/to/repo --to clean-task --require-include --dry-run

wt-copy-local /path/to/repo /path/to/repo.worktrees/clean-task
wt step copy-ignored --from /path/to/repo --to clean-task --require-include
```

## Help

```sh
wt --help
wt switch --help
wt-copy-local --help
```
