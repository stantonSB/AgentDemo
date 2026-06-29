#!/usr/bin/env bash
# Minimal assertion helpers for the hook test suite. No external deps.
# Each failing assertion prints a FAIL line and exits 1.

assert_eq() { # <expected> <actual> <msg>
  if [ "$1" != "$2" ]; then
    echo "FAIL: $3: expected [$1] but got [$2]" >&2
    exit 1
  fi
}

assert_contains() { # <haystack> <needle> <msg>
  case "$1" in
    *"$2"*) : ;;
    *) echo "FAIL: $3: [$1] does not contain [$2]" >&2; exit 1 ;;
  esac
}

assert_file_exists() { # <path> <msg>
  if [ ! -f "$1" ]; then
    echo "FAIL: $2: file [$1] does not exist" >&2
    exit 1
  fi
}
