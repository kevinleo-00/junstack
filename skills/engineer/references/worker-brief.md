# Worker brief

Send each implementation worker this brief with the placeholders filled in. Point to files by path; don't paste them. When the worker is a pstack `poteto-agent`, put poteto-mode's required first line (`Read <poteto-mode folder>/worker.md before anything else.`) above everything else.

```
Goal: implement ticket <NN> of <slug> so its acceptance criteria hold and its Verify commands pass.

Read first:
- Ticket: <abs path>/docs/engineering/<slug>/tickets/<NN-...>.md
- Design: <abs path>/docs/engineering/<slug>/DESIGN.md - sections: <list>
- Spec (for intent only): <abs path>/docs/engineering/<slug>/SPEC.md
- Project rules: <AGENTS.md / CLAUDE.md paths>

Workspace: you are in your own git worktree on branch <worker-branch>, created from engineer/<slug> at <sha>. Work and commit only here.

Rules:
- Write a failing test that captures the acceptance criteria, watch it fail, then implement until it passes. Skip the test only when no reasonable test seam exists, and explain why.
- Change only files inside the write scope: <scope>. If you can't finish without going outside it, stop and report a blocker.
- Do not spawn agents, push, merge, rebase onto other branches, or edit docs/engineering/.
- Follow the design. If the design can't work as written, stop and report a blocker with evidence (failing test, error output). Do not invent a different design.
- Run the ticket's Verify commands and the project's fast test suite before you report.
- Commit with a conventional message, for example `feat(<area>): <what>`.

Report, in this order:
1. Status: done | blocked
2. Branch and commit SHA(s)
3. Files changed
4. Each command you ran, its exit code, and the last lines of its output
5. Limitations or follow-ups
6. Blocker (if blocked): what in the design or ticket doesn't hold, with evidence
```
