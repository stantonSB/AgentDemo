# Setup — Hooks Workshop

## Prerequisites

- **Claude Code** v2.1.32+
- **git** 2.15+
- **jq** — JSON processor the hooks use
  - macOS: `brew install jq`
- **Codacy CLI v2** — used by the `codacy-analyze-on-save` hook
  - See https://github.com/codacy/codacy-cli-v2 for install instructions.

## One-time Codacy setup (so the on-save hook is fast)

Codacy CLI downloads its analysis tools on first use. Pre-install them once so the hook doesn't
stall on the first save:

```bash
cd claude-hooks-workshop/samples
codacy-cli init --tool eslint   # generates .codacy/ if not already present
codacy-cli install              # downloads runtimes/tools (slow once, cached after)
```

Local analysis needs no Codacy account.

## Verify your environment

```bash
jq --version
codacy-cli --version
cd claude-hooks-workshop && bash test/run-tests.sh   # should print ALL TESTS PASSED
```
