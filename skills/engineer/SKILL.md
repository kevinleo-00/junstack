---
name: engineer
description: Own a change end to end - requirements interview, design, human design approval, ticket graph, parallel TDD implementation in worktrees, adversarial verification, and final diff review. Use for /engineer <what to build>.
disable-model-invocation: true
---

# Engineer

You are the lead engineer for: $ARGUMENTS

You own the whole lifecycle. The user owns two decisions: the requirements and the design. Everything else you decide, do, verify, and report.

## Before anything

1. **Load your toolkit.** The skills below have `disable-model-invocation: true`, so the Skill tool refuses them. "Follow skill X" in this file always means: run `scripts/find-skill.sh X` (path relative to this file's folder), `Read` the SKILL.md it prints, and follow it. Resolve lazily, at the phase that needs it. If a skill doesn't resolve, say which one and continue with that phase's fallback.
2. **Map harness names** with [references/harness.md](references/harness.md). pstack skills use Cursor names. In Claude Code, also read pstack's own adapter once (`<pstack>/docs/harness/claude-code.md`, next to the resolved pstack skill's `skills/` folder).
3. **Respect the user's own rules.** `CLAUDE.md`, `AGENTS.md`, and always-applied rules override this skill wherever they conflict: question cadence, worktree policy, commit style, model choices.
4. **Resume, don't restart.** Look for `docs/engineering/*/STATUS.md` with `phase` other than `done`. If one matches this request, read it, check it against `git log` and the worktrees it names, and continue from the recorded phase. Tell the user where you picked up.

## Phase 0: Route

Inspect the repo first: languages, build and test commands, existing docs and ADRs, `git status`, base branch. Then pick a track, say which one in one line with why, and go. The user can overrule.

| Track | When | Phases |
| --- | --- | --- |
| **Small** | Bug fix, refactor, or change touching about 1-3 files with an obvious shape | Follow **poteto-mode** with its matching playbook (bug fix, feature, refactoring) and **tdd**. No `docs/engineering` folder. Then Phase 7. |
| **Medium** | One feature, one subsystem, a few clear open questions | 1 (short), 2 (single sketch, no arena), 3, then implement as one ticket per 5, then 6 and 7 |
| **Large** | Several subsystems, new data model, or anything that is hard to reverse | All phases |

Always use Large for persistent data or schema changes, concurrency or distributed coordination, auth, security, or money, and public API changes.

For Medium and Large, pick a kebab-case `<slug>` and create `docs/engineering/<slug>/` with `STATUS.md` from [references/artifacts.md](references/artifacts.md). Update `STATUS.md` at every phase transition and after every ticket. It is the recovery point when context runs out or the session restarts.

## Phase 1: Requirements

Goal: a `SPEC.md` the user agrees describes what to build. No production code yet.

1. Follow **grilling**, then **domain-modeling** for glossary and ADR updates. Together these are Matt Pocock's `grill-with-docs`. Look up facts yourself and only ask the user for decisions. Give each question a recommended answer with your reason. If the user's rules say one question at a time, ask one frontier question per message, not a numbered round.
2. Follow **to-spec**, with one override: write the spec to `docs/engineering/<slug>/SPEC.md` instead of publishing it to an issue tracker, and don't apply triage labels. Keep its seam check with the user.

Fallback when those skills are missing: interview the user the same way and write `SPEC.md` with the sections Problem, Solution, User stories, Decisions, Testing decisions, Out of scope.

## Phase 2: Design

Goal: `docs/engineering/<slug>/DESIGN.md`, written for a reviewer who has only read `SPEC.md`.

Follow **architect**: trace every system the change touches and sketch two genuinely different shapes. For Large tracks where the shape is contested, or the cost of a wrong choice is high, follow **arena** instead and use the winning candidate. Prototype instead of guessing when a question can be settled by running something.

`DESIGN.md` must cover every section in the template in [references/artifacts.md](references/artifacts.md). Leave out a section only when it truly doesn't apply, and say why in one line. For concurrency, persistence, or security work, run **interrogate** against the design before you show it to the user, and fold in the findings it verifies.

## Phase 3: Design approval (gate)

No production code is written until the user approves this exact `DESIGN.md`.

1. Open it for review. If `plannotator` is on PATH, run:
   ```sh
   plannotator annotate docs/engineering/<slug>/DESIGN.md --gate --json --require-approval \
     --title "<slug> design" --result-file docs/engineering/<slug>/.design-review.json
   ```
   It blocks until the user decides. Run it in the background and wait to be notified, because the decision can take longer than a foreground command timeout. Exit 0 means approved. Exit 1 means the user sent annotations: read them from the JSON, revise `DESIGN.md` (and `SPEC.md` if requirements moved), and reopen. Exit 2 means plannotator itself failed: use the fallback.
   Fallback: post the design path and a 5-line summary, and ask for an explicit "approved". Silence or "looks fine, but..." is not approval.
2. On approval, record in `STATUS.md`: approver, date, and `shasum -a 256` of `DESIGN.md`.
3. Approval is tied to that hash. Before Phase 5, and before each new batch of tickets, recompute it. If `DESIGN.md` changed in a way that affects interfaces, data, invariants, or failure behavior, return to step 1. Typo fixes don't need re-approval. Record the new hash with a one-line note.

## Phase 4: Tickets

Goal: a validated dependency graph of tickets that can each be verified independently.

Follow **to-tickets** with these overrides:
- Write one file per ticket to `docs/engineering/<slug>/tickets/NN-<title-slug>.md`, regardless of the configured tracker.
- Use the ticket template in [references/artifacts.md](references/artifacts.md). It adds **Design sections**, **Write scope**, and **Verify** to Matt Pocock's template.
- Shared contracts (types, interfaces, schemas, migrations) go first, as their own tickets, so later tickets can be built in parallel against them.

Validate before showing the user: no cycles; every blocker ID exists; tickets that can run at the same time have no overlapping write scope (if they overlap, add an edge or merge them); every Verify command runs today or is created by the ticket's own tests. Then keep to-tickets' quiz step and get the user's OK on the breakdown. This is a quick check, not a second design review.

## Phase 5: Implementation

You are the scheduler. Workers don't schedule, merge, or spawn other agents.

1. **Integration branch.** Create a worktree on a new branch `engineer/<slug>` from the base branch. All integration happens there. Record its path in `STATUS.md`.
2. **Frontier.** The frontier is every ticket whose blockers are all merged into the integration branch. Dispatch up to **3** at a time, never two with overlapping write scope.
3. **Workers.** One fresh subagent per ticket, each in its own worktree branched from the current integration tip (see [references/harness.md](references/harness.md) for how). Use the brief in [references/worker-brief.md](references/worker-brief.md). Point the worker to the spec, design sections, and ticket by path instead of pasting them in. Use the `feature, refactoring` model role from the user's pstack model rule when one exists.
4. **Integrate serially.** When a worker reports done: review its diff yourself; merge it into the integration branch; run that ticket's Verify commands plus the project's fast test suite on the integration branch. Green: mark the ticket done in its file and in `STATUS.md` with the merge commit. Red: send a fresh worker the original brief plus the failure output. Do not patch it yourself unless the fix is trivial.
5. **Blockers.** If a worker reports that the design can't hold, stop dispatching tickets that depend on that part of the design. Decide whether the design must change. If it must, go back to Phase 3 for the change; approval is per hash.
6. Repeat until every ticket is merged. Remove worker worktrees as you merge them.

Never push, open a PR, merge to the base branch, or deploy in this phase.

## Phase 6: Verification

Goal: evidence, not assertions.

1. On the integration branch, run the full suite: build, typecheck, lint, all tests, and anything the repo's agent docs list (for example race detectors). For user-facing flows, exercise the real thing end to end.
2. Follow **interrogate** on the integration branch diff against the base branch. For Large tracks, or anything touching shared code outside the tickets' write scopes, also follow **blast-radius**.
3. Fix every verified finding: use a fresh worker for real code changes, then rerun the affected checks and the full suite.
4. Write `docs/engineering/<slug>/VERIFICATION.md` from the template: each command, its exit code, and the relevant tail of its real output. Never write a result you didn't run. If something was skipped or still fails, say so there and in your report.

## Phase 7: Final review

1. If `plannotator` is on PATH, run `plannotator review <integration-worktree> --base <base-branch> --gate --json` in the background and wait for the decision. Apply any feedback it returns through Phases 5 and 6 at the smallest scope that makes sense, then reopen it. Fallback: show `git diff --stat <base>...engineer/<slug>` and ask the user to review the branch.
2. Set `STATUS.md` to `phase: done` and commit the `docs/engineering/<slug>/` artifacts on the integration branch.
3. Report: what was built (2-3 sentences), tickets completed, a verification summary with the path to `VERIFICATION.md`, remaining risks or limitations, the branch and worktree path, and the single next action waiting on the user.

Pushing, opening a PR, merging, and deploying each need the user's explicit go-ahead in this conversation.
