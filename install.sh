#!/usr/bin/env bash
# Install the /engineer skill for Claude Code and Cursor (Cursor also loads
# skills from ~/.claude/skills) by symlinking it to this repo, so a `git pull`
# here updates every harness at once.
#
#   ./install.sh              install (idempotent)
#   ./install.sh --uninstall  remove the symlink, only if it points here
#
# Never overwrites or removes an `engineer` skill it did not create.
set -euo pipefail

src="$(cd "$(dirname "$0")" && pwd)/skills/engineer"
dest="$HOME/.claude/skills/engineer"

ours() { [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; }

case "${1:-}" in
  --uninstall)
    if ours; then
      rm "$dest"
      echo "Removed $dest"
      exit 0
    fi
    if [ -e "$dest" ] || [ -L "$dest" ]; then
      echo "Refusing to remove $dest: it was not installed from $src" >&2
      exit 1
    fi
    echo "Nothing to remove at $dest"
    exit 0
    ;;
  "") ;;
  *)
    echo "usage: install.sh [--uninstall]" >&2
    exit 2
    ;;
esac

if ours; then
  echo "Already installed: $dest -> $src"
  exit 0
fi

if [ -e "$dest" ] || [ -L "$dest" ]; then
  echo "Refusing to overwrite existing $dest" >&2
  echo "Move it aside first if you want this repo's /engineer skill." >&2
  exit 1
fi

mkdir -p "$(dirname "$dest")"
ln -s "$src" "$dest"
chmod +x "$src/scripts/"*.sh
echo "Installed: $dest -> $src"
echo "Restart Claude Code or Cursor, then run: /engineer <what to build>"
