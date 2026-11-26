# Engineering artifacts

Everything for one change lives in `docs/engineering/<slug>/`:

```
docs/engineering/<slug>/
├── STATUS.md          progress, approvals, branches - the recovery point
├── SPEC.md            agreed requirements (Phase 1)
├── DESIGN.md          approved design (Phases 2-3)
├── tickets/NN-*.md    one file per ticket (Phase 4)
└── VERIFICATION.md    real command output (Phase 6)
```

## STATUS.md

```markdown
# <slug>

- phase: route | requirements | design | approval | tickets | implementation | verification | review | done
- track: medium | large
- base branch: <branch> @ <sha at start>
- integration branch: engineer/<slug>
- integration worktree: <absolute path>

## Design approval

| date | approver | DESIGN.md sha256 | note |
| --- | --- | --- | --- |

## Tickets

| id | title | status | worker branch | merge commit |
| --- | --- | --- | --- | --- |

status: blocked | ready | in-progress | merged | failed

## Blockers and decisions

- <date>: <what happened, what was decided, by whom>
```

## DESIGN.md

```markdown
# <Feature> design

Spec: ./SPEC.md

## Requirements and constraints
What the design must satisfy, pulled from SPEC.md, plus non-functional limits (latency, scale, compatibility).

## Proposed architecture
Modules, boundaries, and how a request or job flows through them. A diagram if it helps.

## Alternatives considered
At least one genuinely different shape, and why it lost.

## Interfaces and data models
Types, signatures, schemas, wire formats. Code blocks are fine here.

## State ownership and invariants
Each piece of state has one owner. List the invariants that must always hold.

## Failure handling and recovery
What fails, how it is detected, what retries and is idempotent, and what the user sees.

## Concurrency and consistency
Who runs concurrently, what is shared, ordering and isolation guarantees.

## Testing strategy
Which seams are tested, at what level, and the commands that run them.

## Rollout and compatibility
Migrations, feature flags, backward compatibility. Omit when nothing ships to users.
```

## Ticket (tickets/NN-title-slug.md)

Matt Pocock's local ticket template, with three fields added for parallel workers.

```markdown
# NN: <Ticket title>

**What to build:** the end-to-end behavior this ticket makes work, from the user's perspective.

**Blocked by:** NN, NN - or "None (can start immediately)".

**Design sections:** the DESIGN.md headings this ticket implements.

**Write scope:** directories or modules this ticket may change. Parallel tickets must not overlap.

**Verify:**
- `<command that proves this ticket works>`

**Status:** ready-for-agent

- [ ] Acceptance criterion 1
- [ ] Acceptance criterion 2
```

## VERIFICATION.md

```markdown
# <slug> verification

- integration branch: engineer/<slug> @ <sha>
- base: <branch> @ <sha>
- date: <date>

## Commands

### `<command>`
exit: 0

<last relevant lines of the real output>

## Adversarial review
interrogate: <N verified findings, each with its fix commit, or "no verified findings">
blast-radius: <result, or "not run: <reason>">

## Skipped or failing
<anything not run or still red, and why - or "none">
```
