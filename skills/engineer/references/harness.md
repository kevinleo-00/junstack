# Harness mapping

This skill runs in Claude Code and Cursor. Use whichever name the session actually offers.

| Concept | Claude Code | Cursor |
| --- | --- | --- |
| Spawn a subagent | `Agent` (`subagent_type: "general-purpose"`, or `pstack:poteto-agent`) | `Task` (`subagent_type: generalPurpose`, or `poteto-agent`) |
| Ask the user a structured question | `AskUserQuestion` | `AskQuestion` |
| Track phases | `TodoWrite` if offered, otherwise a list in your reply | todolist tool |
| Run another skill | `Read` the path from `scripts/find-skill.sh <name>` | Same |
| pstack per-role models | `~/.claude/rules/pstack-models.md` (already in context when present) | `~/.cursor/rules/pstack-models.mdc` |
| Long-running blocking command (plannotator gate) | `Bash` with `run_in_background: true`, then wait for the completion notice | Run in a background terminal and wait |

## Worker worktrees

Create worker worktrees yourself with git so they branch from the **integration tip**, not from whatever the harness checks out by default. Name worker branches `engineer/<slug>--<NN>`: git refuses to create a branch nested under an existing branch name, so a slash after the integration branch name fails.

```sh
git -C <integration-worktree> worktree add -b engineer/<slug>--<NN> \
  <repo-parent>/<repo>-<slug>-<NN> engineer/<slug>
```

Pass the absolute worktree path in the brief. Tell the worker to work only there, using absolute paths or `git -C`. Don't use the harness's built-in worktree isolation (`isolation: "worktree"` in Claude Code, cloud environments in Cursor) for these workers: it branches from the session's checkout, which doesn't include the integrated predecessor tickets.

Merge a finished worker from the integration worktree:

```sh
git -C <integration-worktree> merge --no-ff engineer/<slug>--<NN> -m "merge(<slug>): ticket <NN> <title>"
git -C <integration-worktree> worktree remove <worker-worktree>
git -C <integration-worktree> branch -d engineer/<slug>--<NN>
```

If the merge conflicts, the write scopes overlapped or a ticket strayed outside its scope. Abort the merge (`git merge --abort`) and send a fresh worker, branched from the new tip, the original brief plus the conflict. Then tighten the scope rules in the remaining tickets.

## Gotchas

- Subagents don't inherit slash-command skills. Anything a worker must follow goes in its brief, or as a path the brief tells it to read.
- `disable-model-invocation: true` blocks the Skill tool, not `Read`. That is why every delegated skill is loaded by path.
- In non-interactive runs (`claude -p`), there is no structured question tool. Ask in plain text and stop at each gate.
