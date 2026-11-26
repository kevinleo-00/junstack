# jstack

Personal agent skills for Claude Code and Cursor.

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

```sh
./install.sh             # symlinks ~/.claude/skills/engineer -> this repo
./install.sh --uninstall # removes the symlink, only if it points here
```

Cursor loads skills from `~/.claude/skills`, so one install covers both. Updating is `git pull`. The installer never overwrites an `engineer` skill it didn't create.

### Test

```sh
./tests/run.sh                      # all tests, including a check that every delegated skill resolves on this machine
ENGINEER_SKIP_LIVE=1 ./tests/run.sh # skip the machine-specific check
```
