# Setup — Hooks Workshop

## Prerequisites

- **Claude Code** v2.1.32+
- **git** 2.15+
- **jq** — JSON processor the hooks use
  - macOS: `brew install jq`
  - Linux: `sudo apt-get install jq` (or your distro's package manager)
- **Codacy CLI v2** — used by the `codacy-analyze-on-save` hook
  - See https://github.com/codacy/codacy-cli-v2 for install instructions.

## One-time Codacy setup (so the on-save hook is fast)

Codacy CLI downloads its analysis tools on first use. Pre-install them once so the hook doesn't
stall on the first save:

```bash
# Run from the repo root; the subshell keeps your shell's cwd unchanged.
( cd claude-hooks-workshop/samples && codacy-cli init --tool eslint && codacy-cli install )
# init generates .codacy/ if not already present; install downloads runtimes/tools
# (slow once, cached after).
```

Local analysis needs no Codacy account.

## Verify your environment

```bash
# Run from the repo root; the subshell keeps your shell's cwd unchanged.
jq --version
codacy-cli --version
( cd claude-hooks-workshop && bash test/run-tests.sh )   # should print ALL TESTS PASSED
```
