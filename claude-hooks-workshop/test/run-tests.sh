#!/usr/bin/env bash
# Run every test_*.sh in this directory. Exits non-zero if any fail.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
fail=0
for t in "$HERE"/test_*.sh; do
  [ -e "$t" ] || continue
  if bash "$t"; then
    :
  else
    echo "FAILED: $t" >&2
    fail=1
  fi
done
if [ "$fail" -eq 0 ]; then
  echo "ALL TESTS PASSED"
else
  echo "SOME TESTS FAILED" >&2
fi
exit "$fail"
