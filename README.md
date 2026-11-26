# junstack

Agent skills for Claude Code and Cursor.

## /engineer

`/engineer <what to build>` runs the whole engineering lifecycle: requirements interview, design, design approval, ticket graph, parallel TDD implementation in git worktrees, adversarial verification, and final diff review. You make two decisions: requirements and design. The agent does the rest and stops before pushing anything.

It doesn't add its own orchestration runtime. It chains skills you already have installed, using the harness's native subagents:

| Phase | Skills used | Output |
| --- | --- | --- |
| Requirements | Matt Pocock `grilling` + `domain-modeling` (`grill-with-docs`), `to-spec` | `SPEC.md` |
| Design | pstack `architect`, `arena` for contested designs | `DESIGN.md` |
| Approval gate | Plannotator `annotate --gate --require-approval` | sha256 recorded in `STATUS.md` |
| Tickets | Matt Pocock `to-tickets` | `tickets/NN-*.md` |
| Implementation | pstack `poteto-mode` style, up to 3 subagents in their own worktrees | `engineer/<slug>` branch |
| Verification | pstack `interrogate`, `blast-radius` | `VERIFICATION.md` |
| Final review | Plannotator `review --gate` | - |

Artifacts live in `docs/engineering/<slug>/` in the target repo. `STATUS.md` lets a new session resume where the last one stopped.

### Why it loads skills by path

Almost every skill above sets `disable-model-invocation: true`, so the Skill tool refuses to call them from another skill. `/engineer` runs `scripts/find-skill.sh <name>` to find the installed SKILL.md (personal skills first, then the newest plugin version) and reads it. pstack's own Claude Code adapter does the same thing.

### Prerequisites

- [Matt Pocock's skills](https://github.com/mattpocock/skills): `/plugin install mattpocock-skills` in Claude Code, or `npx skills add mattpocock/skills -g`
- [pstack](https://github.com/cursor/plugins/tree/main/pstack): `/plugin marketplace add cursor/plugins` then `/plugin install pstack@cursor-plugins`, then `/pstack:setup-pstack`
- [Plannotator](https://plannotator.ai) CLI on `PATH` (optional - without it, the gates fall back to asking in chat)

You don't need to run `/setup-matt-pocock-skills` per repo: `/engineer` writes the spec and tickets to `docs/engineering/<slug>/` instead of an issue tracker.

### Install

Pick one. Installing more than one way gives you two copies of the skill.

**Claude Code plugin.** The command becomes `/junstack:engineer`.

```
/plugin install junstack --marketplace kevinleo-00/junstack
```

On Claude Code versions before 2.1.275, use two steps: `/plugin marketplace add kevinleo-00/junstack`, then `/plugin install junstack@junstack`.

**skills CLI** (Claude Code, Cursor, and other agents):

```sh
npx skills add kevinleo-00/junstack -g
```

**Clone and link.** Best if you want to edit the skill: `git pull` updates it everywhere. Cursor also loads `~/.claude/skills`, so one link covers both harnesses.

```sh
git clone https://github.com/kevinleo-00/junstack.git
cd junstack && ./install.sh   # symlinks ~/.claude/skills/engineer -> this clone
./install.sh --uninstall      # removes the symlink, only if it points here
```

The installer never overwrites an `engineer` skill it didn't create.

### Permissions

`/engineer` reads its own templates and the SKILL.md files of the skills it builds on. To avoid a permission prompt on each read (and blocked reads in `claude -p`), add these to `permissions.allow` in `~/.claude/settings.json`:

```json
"Read(~/.claude/skills/**)",
"Read(~/.claude/plugins/cache/**)",
"Bash(~/.claude/skills/engineer/scripts/find-skill.sh:*)"
```

### Test

```sh
./tests/run.sh                      # all tests, including a check that every delegated skill resolves on this machine
ENGINEER_SKIP_LIVE=1 ./tests/run.sh # skip the machine-specific check
```
