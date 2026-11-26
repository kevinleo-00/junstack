#!/usr/bin/env bash
# Print the absolute path of an installed skill's SKILL.md.
#
#   find-skill.sh <skill-name>
#
# Most skills /engineer builds on set `disable-model-invocation: true`, so the
# Skill tool refuses them. The portable way to "run" one is to read its
# SKILL.md and follow it. This script finds that file in both Claude Code and
# Cursor installs:
#
#   1. Personal skills: ~/.claude/skills, ~/.cursor/skills, ~/.agents/skills
#   2. Plugin caches:   ~/.claude/plugins/cache, ~/.cursor/plugins (any depth,
#                       newest version wins, deprecated/ folders ignored)
#
# A match requires both the folder name and the frontmatter `name:` to equal
# <skill-name>. Exits 1 with a message on stderr when nothing matches.
set -euo pipefail

name="${1:-}"
if [ -z "$name" ]; then
  echo "usage: find-skill.sh <skill-name>" >&2
  exit 2
fi

has_name() { # has_name <SKILL.md>: frontmatter declares exactly this name
  awk -v want="$name" '
    NR == 1 && $0 != "---" { exit 1 }
    NR > 1 && $0 == "---" { exit 1 }
    NR > 1 && /^name:/ { sub(/^name:[ \t]*/, ""); gsub(/["\047]/, ""); exit ($0 == want ? 0 : 1) }
  ' "$1"
}

for root in "$HOME/.claude/skills" "$HOME/.cursor/skills" "$HOME/.agents/skills"; do
  f="$root/$name/SKILL.md"
  if [ -f "$f" ] && has_name "$f"; then
    echo "$f"
    exit 0
  fi
done

# Plugin caches: emit "<sortable-version>\t<path>", keep the highest version.
best="$(
  for root in "$HOME/.claude/plugins/cache" "$HOME/.cursor/plugins"; do
    [ -d "$root" ] || continue
    find -L "$root" -maxdepth 9 -type f -path "*/$name/SKILL.md" -not -path "*/deprecated/*" 2>/dev/null
  done | while IFS= read -r f; do
    has_name "$f" || continue
    # The version is the last path segment that looks like 1.2.3; pad each
    # part so a plain string sort orders 0.15.48 above 0.9.2.
    ver="$(echo "$f" | tr '/' '\n' | grep -E '^[0-9]+(\.[0-9]+)+$' | tail -1 || true)"
    key="$(echo "${ver:-0}" | awk -F. '{ for (i = 1; i <= 4; i++) printf "%08d", ($i == "" ? 0 : $i) }')"
    printf '%s\t%s\n' "$key" "$f"
  done | sort -r | head -1 | cut -f2-
)"

if [ -n "$best" ]; then
  echo "$best"
  exit 0
fi

echo "find-skill: no installed skill named '$name' (searched ~/.claude, ~/.cursor, ~/.agents skills and plugin caches)" >&2
exit 1
