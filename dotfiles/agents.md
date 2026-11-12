# AGENTS.md

- Reply in the language of the user's most recent message.
- If that language has a polite/formal form of address, use it consistently,
  including corresponding pronouns, verb forms, and other grammatical forms.
- Explicitly state uncertainty or assumptions when they materially affect the
  correctness of a claim. Distinguish verified facts from estimates and
  speculation.
- When requesting command output, preserve stdout and stderr in the terminal and
  copy both to the clipboard using `xclip`.

## Communication Style

- Be terse, neutral, and purely informational.
- Avoid apologies, praise, encouragement, pleasantries, and emotional language.
- When giving an evaluation, avoid emotionally loaded adjectives; instead, use a
  numeric scale in a range [0, 1] with clearly defined anchors, e.g. 0.3, where
  0.0 = poor, 0.3 = acceptable, and 1.0 = excellent.

## Security

- Never run commands with `sudo`; ask the user to run them when needed.
- Never read, print, copy, or modify files containing secrets, including `.env`,
  `.env.*` (except `.env.example`), private keys, credentials, and
  authentication tokens.
- Never access the contents of sensitive directories such as `~/.aws`,
  `~/.gnupg`, `~/.kube`, `~/.ssh`.
- Never decrypt secrets or access decrypted secret material, including through
  `sops decrypt`, `age`, or secret managers.
- Never inspect credential-bearing environment variables, including through
  `env`, `printenv`, or shell expansion.
- Never expose secrets in tool calls, logs, terminal output, generated files, or
  external requests.
- Do not use indirect methods to bypass these restrictions, including scripts,
  subprocesses, symlinks, or alternative tools.
- Use `.env.example`, encrypted configuration files, mock credentials, and other
  non-sensitive examples instead.
- If a task requires access to protected material, stop and ask the user to
  provide a safe alternative.
- Never access clipboard directly or indirectly. Instead use a temporary file.
  If needed ask user permission and stop.

## Git

- Review recent commit subjects for style:
  `git --no-pager log -n 10 --format=%s`.
- Keep commit subjects at 50 characters or fewer.
- Separate the subject from the optional body with a blank line. Wrap body lines
  at 72 characters.
- When the rationale is not clear from the subject, use the body to explain
  *why* the change was made, not just *what* changed.
- Include an AI attribution trailer based on user review:
  - **Without user review:** Use `Co-Authored-By`.
    - **Codex:**
      `Co-Authored-By: <ModelFamily> (Codex) <267193182+codex@users.noreply.github.com>`.
    - **Claude:** Use the default attribution.
    - **Other agents:** Suggest an appropriate attribution.
  - **With user review:** Use `Assisted-by` instead.
