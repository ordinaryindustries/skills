---
name: build
description: Take one issue, several issues or a parent's issues through red, green and refactor on their own branches, committing at each step, then rebase onto the feature branch, run the checks, merge, push and mark each one done. Several issues run as worker subagents in worktrees, merged one at a time. Use after slice, when the user asks to build an issue, several issues or a feature.
---

Build issues end to end with red/green TDD, so the feature branch gains one working slice per issue.

Only the user merges into main. Never merge into main, and never push to main.

Stopping stuck workers and handling amendments are not covered yet.

## 1. Check

- **Config**: read `docs/agents/tracker.md` and `docs/agents/checks.md`. If either is missing, tell the user to run `setup` and stop.
- **Input**: one issue, several issues, or a parent. If the user didn't name any, ask which. For a parent, its issues are its children from List issues.
- **Spec**: read the parent's spec and any approved amendments through Read the parent.
- **Working tree**: if `git status` shows uncommitted changes, tell the user and stop.

One issue runs in this session (step 3). Several issues or a parent run as an orchestrator with workers (step 4).

## 2. Feature branch

`feature/<feature>`, where `<feature>` is the parent's kebab-case name, or a short kebab-case name from its title if the tracker has none. If the branch doesn't exist, create it from main. Switch to it.

Each issue gets its own issue branch, `slice/<feature>/<issue>-<slug>`, where `<issue>` is the issue's number and `<slug>` a short kebab-case name from its title. If an issue branch already exists, ask the user whether to resume it or start over.

## 3. One issue

- Read the issue's body: the behavior, the modules and the acceptance criteria.
- **Blockers**: run List issues and find this issue's blockers. If any is not done, name it and stop.
- Create the issue branch from the feature branch and switch to it. State both branch names to the user.
- Set status to in progress through Set status.
- Run the Loop, then Merge.

Then tell the user what merged: the issue, its commits and the feature branch, and whether it was pushed. Tell them to run `build` on the next ready issue or the parent, and to run `review` once every issue in the feature is done.

## 4. Several issues

You are the orchestrator. Stay on the feature branch in the main checkout, so each worker's worktree starts from it. Workers write code; you own the tracker and the merges.

- **Ready**: run List issues. An issue in the set is ready when it is open and every blocker is done. A blocker outside the set counts too.
- **Start**: for each ready issue, set status to in progress through Set status, then start one worker with the Agent tool: a regular subagent, not a fork, with `isolation: "worktree"`. Forks can't start further forks. Give it the worker prompt below. Start every ready issue at once; workers run in parallel.
- **Merge, one at a time**: when a worker reports done, run Merge on its branch. Finish one merge before starting the next, so each issue rebases onto everything merged before it.
- **Repeat**: after each merge, run List issues again and start any issue that is now ready.
- **Stop** when no worker is running and nothing is ready, then give the summary.

State the feature branch and each issue branch to the user as workers start.

### Worker prompt

A worker starts with none of this session's context. Its prompt carries:

- The issue: its number, title and full body.
- Where the spec is, and the approved amendments to read with it.
- The feature branch, and the issue branch name to use.
- The check command from `docs/agents/checks.md`.
- That `docs/agents/tracker.md` is the tracker file, and that it must follow its rules on where tracker files live. Local `.scratch/` lives only in the main checkout, never in a worktree.
- That it doesn't change issue status, merge or push. You do.
- The Loop section of this skill, and the Commits section, copied in full.
- What to report back: the issue branch, the worktree path and the commits, or why it stopped.

Tell the worker to start by renaming its worktree's branch with `git branch -m <issue branch>`. If `git rev-parse HEAD` differs from `git rev-parse <feature branch>`, it stops and reports.

### Summary

End in the session with:

- **Merged**: each issue, its commits, and whether the feature branch was pushed.
- **Blocked**: each issue not built, and why: which blocker isn't done, or what stopped it.
- **Problems**: failed checks, conflicts, stopped workers, a skipped push.

Never assign issues to the user. Tell them to run `build` again once blockers clear, and `review` once every issue in the feature is done.

## Loop

Run this in the issue branch: in the session for one issue, in its worktree for a worker.

### Red

- Write one test per acceptance criterion, each checking that behavior and nothing else. Follow the repo's existing test layout and style.
- Run the new tests and confirm each one fails for the reason it should: the behavior is missing, not a typo or a broken import. If a test passes before any code is written, stop and tell the user, or the orchestrator if you are a worker. The spec or the slicing is wrong.
- Commit the tests.

### Green

- Implement the behavior through the modules the issue lists, until every new test passes. Change only what the issue needs.
- Run the full test suite, so nothing else broke.
- Commit.

### Refactor

- Clean up what you wrote: names, duplication, structure. Change no behavior.
- Run the tests again. They must still pass.
- Commit. If nothing needed cleaning up, say so and skip the commit.

## Merge

For one issue, run this yourself. For several, the orchestrator runs it for each finished worker, one at a time, in that worker's worktree.

- Rebase the issue branch onto the latest feature branch. Resolve any conflicts and run the tests again.
- Run the check command from `docs/agents/checks.md`, from the root of the checkout the issue branch is in. If it fails, fix the cause, commit and run it again; as orchestrator, send the failure back to the worker with SendMessage to fix and commit. Never merge on a failing check. If it can't be made to pass, leave the issue in progress, tell the user (or list it under Problems) and move on.
- Once it passes, in the main checkout on the feature branch, merge the issue branch with `git merge --ff-only`. For a worker, remove its worktree with `git worktree remove`. Then delete the issue branch.
- **Push**: if `git remote` is empty, skip the push and say so. Otherwise push the feature branch: `git push -u origin <feature branch>` the first time, `git push` after. Never push to main.
- Run Tick criteria from `docs/agents/tracker.md` for the criteria the issue built, then set status to done through Set status.

## Commits

Match the repo's own conventions: read `git log` for the message style, and follow any commit rules in the agent file. Reference the issue in each message. Commit only on the issue branch, never on main.
