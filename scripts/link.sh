#!/usr/bin/env bash
# Links each skill in this repo into ~/.claude/skills, one folder at a time.
# Skips any name already there, so it never replaces a user's own skills.
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
dest="$HOME/.claude/skills"

mkdir -p "$dest"

for src in "$repo"/skills/*/; do
  src="${src%/}"
  name="$(basename "$src")"
  link="$dest/$name"

  if [ -L "$link" ] && [ "$(readlink "$link")" = "$src" ]; then
    echo "already linked: $name"
  elif [ -e "$link" ] || [ -L "$link" ]; then
    echo "skipped: $name (already exists at $link)"
  else
    ln -s "$src" "$link"
    echo "linked: $name"
  fi
done
