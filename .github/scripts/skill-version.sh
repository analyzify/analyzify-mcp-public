#!/usr/bin/env bash
# Prints the version: of a SKILL.md's frontmatter (the block between the
# first two "---" lines), from the file named, or stdin. Fails unless it is
# plain x.y.z. The installed-skill check reads the same line.
set -euo pipefail
# awk reads to the end (no exit), so a writer piping into it never gets SIGPIPE.
v=$(awk '
  done { next }
  NR == 1 { if ($0 != "---") done = 1; next }
  $0 == "---" { done = 1; next }
  /^version:/ { sub(/^version:[ \t]*/, ""); gsub(/["\047\r \t]/, ""); print; done = 1 }
' "${1:-/dev/stdin}")
if ! printf '%s' "$v" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
  echo "no x.y.z version: in the SKILL.md frontmatter (found '${v}')" >&2
  exit 1
fi
printf '%s\n' "$v"
