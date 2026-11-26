#!/usr/bin/env bash
# Behavior tests for the engineer skill's scripts. Each test runs against a
# throwaway fake HOME so nothing touches the real ~/.claude or ~/.cursor.
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FIND="$ROOT/skills/engineer/scripts/find-skill.sh"
INSTALL="$ROOT/install.sh"
PASS=0
FAIL=0

t() { # t <name> <command...>
  local name="$1"; shift
  if ( "$@" ) >/dev/null 2>&1; then PASS=$((PASS + 1)); echo "ok   $name"
  else FAIL=$((FAIL + 1)); echo "FAIL $name"; fi
}

fake_home() {
  local h; h="$(mktemp -d)"
  echo "$h"
}

mkskill() { # mkskill <dir> <name>
  mkdir -p "$1"
  printf -- '---\nname: %s\ndescription: test\n---\nbody\n' "$2" > "$1/SKILL.md"
}

# --- find-skill.sh -----------------------------------------------------------

test_finds_user_skill() {
  local h; h="$(fake_home)"
  mkskill "$h/.claude/skills/foo" foo
  [ "$(HOME="$h" "$FIND" foo)" = "$h/.claude/skills/foo/SKILL.md" ]
}

test_finds_cursor_skill() {
  local h; h="$(fake_home)"
  mkskill "$h/.cursor/skills/foo" foo
  [ "$(HOME="$h" "$FIND" foo)" = "$h/.cursor/skills/foo/SKILL.md" ]
}

test_finds_nested_plugin_skill() {
  local h; h="$(fake_home)"
  mkskill "$h/.claude/plugins/cache/mkt/mattpocock-skills/1.3.1/skills/engineering/to-tickets" to-tickets
  [ "$(HOME="$h" "$FIND" to-tickets)" = "$h/.claude/plugins/cache/mkt/mattpocock-skills/1.3.1/skills/engineering/to-tickets/SKILL.md" ]
}

test_prefers_newest_plugin_version() {
  local h; h="$(fake_home)"
  mkskill "$h/.claude/plugins/cache/mkt/pstack/0.9.2/skills/architect" architect
  mkskill "$h/.claude/plugins/cache/mkt/pstack/0.15.48/skills/architect" architect
  mkskill "$h/.claude/plugins/cache/mkt/pstack/0.15.7/skills/architect" architect
  [ "$(HOME="$h" "$FIND" architect)" = "$h/.claude/plugins/cache/mkt/pstack/0.15.48/skills/architect/SKILL.md" ]
}

test_user_skill_beats_plugin_skill() {
  local h; h="$(fake_home)"
  mkskill "$h/.claude/plugins/cache/mkt/p/1.0.0/skills/foo" foo
  mkskill "$h/.claude/skills/foo" foo
  [ "$(HOME="$h" "$FIND" foo)" = "$h/.claude/skills/foo/SKILL.md" ]
}

test_matches_frontmatter_name_not_just_dir() {
  local h; h="$(fake_home)"
  mkskill "$h/.claude/plugins/cache/mkt/p/1.0.0/skills/foo" bar
  ! HOME="$h" "$FIND" foo
}

test_ignores_deprecated_dirs() {
  local h; h="$(fake_home)"
  mkskill "$h/.claude/plugins/cache/mkt/p/1.0.0/skills/deprecated/foo" foo
  ! HOME="$h" "$FIND" foo
}

test_missing_skill_exits_nonzero_with_message() {
  local h; h="$(fake_home)"
  local out; out="$(HOME="$h" "$FIND" nope 2>&1)" && return 1
  echo "$out" | grep -q "nope"
}

test_requires_argument() {
  ! "$FIND"
}

# --- install.sh --------------------------------------------------------------

test_install_creates_symlink() {
  local h; h="$(fake_home)"
  HOME="$h" "$INSTALL" &&
    [ -L "$h/.claude/skills/engineer" ] &&
    [ "$(readlink "$h/.claude/skills/engineer")" = "$ROOT/skills/engineer" ]
}

test_install_is_idempotent() {
  local h; h="$(fake_home)"
  HOME="$h" "$INSTALL" && HOME="$h" "$INSTALL" &&
    [ "$(readlink "$h/.claude/skills/engineer")" = "$ROOT/skills/engineer" ]
}

test_install_refuses_to_overwrite_real_dir() {
  local h; h="$(fake_home)"
  mkskill "$h/.claude/skills/engineer" engineer
  ! HOME="$h" "$INSTALL" && [ ! -L "$h/.claude/skills/engineer" ] &&
    grep -q "name: engineer" "$h/.claude/skills/engineer/SKILL.md"
}

test_install_refuses_foreign_symlink() {
  local h; h="$(fake_home)"
  mkdir -p "$h/.claude/skills" "$h/elsewhere"
  ln -s "$h/elsewhere" "$h/.claude/skills/engineer"
  ! HOME="$h" "$INSTALL" && [ "$(readlink "$h/.claude/skills/engineer")" = "$h/elsewhere" ]
}

test_uninstall_removes_only_own_symlink() {
  local h; h="$(fake_home)"
  HOME="$h" "$INSTALL" && HOME="$h" "$INSTALL" --uninstall && [ ! -e "$h/.claude/skills/engineer" ]
}

test_uninstall_leaves_foreign_dir() {
  local h; h="$(fake_home)"
  mkskill "$h/.claude/skills/engineer" engineer
  ! HOME="$h" "$INSTALL" --uninstall && [ -f "$h/.claude/skills/engineer/SKILL.md" ]
}

# --- the skill itself --------------------------------------------------------

test_skill_frontmatter() {
  local f="$ROOT/skills/engineer/SKILL.md"
  head -1 "$f" | grep -qx -- '---' &&
    grep -qx 'name: engineer' "$f" &&
    grep -q '^description: ' "$f" &&
    grep -qx 'disable-model-invocation: true' "$f"
}

test_skill_references_exist() {
  # Every relative path the skill points at must exist in the package.
  local dir="$ROOT/skills/engineer" missing=0 p
  for p in $(grep -oE '\((references|scripts)/[A-Za-z0-9._/-]+\)' "$dir/SKILL.md" | tr -d '()' | sort -u); do
    [ -e "$dir/$p" ] || { echo "missing $p" >&2; missing=1; }
  done
  [ "$missing" = 0 ]
}

test_every_delegated_skill_resolves_on_this_machine() {
  # Smoke test against the real HOME: each skill /engineer delegates to must be
  # installed. Skipped (passes) when ENGINEER_SKIP_LIVE=1, e.g. in CI.
  [ "${ENGINEER_SKIP_LIVE:-0}" = 1 ] && return 0
  local s
  for s in grilling domain-modeling to-spec to-tickets architect arena interrogate blast-radius poteto-mode tdd; do
    "$FIND" "$s" >/dev/null || { echo "unresolved $s" >&2; return 1; }
  done
}

test_worker_branches_dont_nest_under_integration_branch() {
  # git refuses refs/heads/engineer/<slug>/<NN> while engineer/<slug> exists,
  # so docs must never name a worker branch under the integration branch.
  ! grep -rnE 'engineer/<slug>/' "$ROOT/skills/engineer"
}

test_plugin_manifest_lists_existing_skills() {
  python3 -I - "$ROOT/.claude-plugin/plugin.json" "$ROOT" <<'EOF'
import json, os, sys
m = json.load(open(sys.argv[1]))
assert m["name"] == "junstack", m["name"]
assert m["skills"], "no skills listed"
for s in m["skills"]:
    assert os.path.isfile(os.path.join(sys.argv[2], s, "SKILL.md")), s
EOF
}

test_marketplace_points_at_plugin() {
  python3 -I - "$ROOT/.claude-plugin/marketplace.json" "$ROOT" <<'EOF'
import json, os, sys
m = json.load(open(sys.argv[1]))
assert m["name"] and m["owner"]["name"]
assert "junstack" in [p["name"] for p in m["plugins"]]
for p in m["plugins"]:
    assert os.path.isfile(os.path.join(sys.argv[2], p["source"], ".claude-plugin", "plugin.json")), p
EOF
}

test_no_personal_paths_or_emails_in_published_files() {
  ! git -C "$ROOT" ls-files -z --cached --others --exclude-standard |
    xargs -0 grep -nE '/Users/[a-z]|@gmail\.com' --
}

test_scripts_are_valid_bash() {
  bash -n "$FIND" && bash -n "$INSTALL"
}

for fn in $(declare -F | awk '{print $3}' | grep '^test_'); do t "$fn" "$fn"; done
echo
echo "$PASS passed, $FAIL failed"
[ "$FAIL" = 0 ]
