---
name: build
description: Take one issue, several issues or a parent's issues through red, green and refactor on their own branches, committing at each step, then rebase onto the feature branch, run the checks, merge, push and mark each one done. Several issues run as worker subagents in worktrees, merged one at a time. Use after slice, when the user asks to build an issue, several issues or a feature.
---

Build issues end to end with red/green TDD, so the feature branch gains one working slice per issue.

Only the user merges into main. Never merge into main, and never push to main.

## 1. Check

- **Config**: read `docs/agents/tracker.md` and `docs/agents/checks.md`. If either is missing, tell the user to run `setup` and stop.
- **Input**: one issue, several issues, or a parent. If the user didn't name any, ask which. For a parent, its issues are its children from List issues.
- **Spec**: read the parent's spec and any approved amendments through Read the parent.
- **Working tree**: if `git status` shows uncommitted changes, tell the user and stop.

One issue runs in this session (step 3). Several issues or a parent run as an orchestrator with workers (step 4).

## 2. Feature branch

`feature/<feature>`, where `<feature>` is the parent's kebab-case name, or a short kebab-case name from its title if the tracker has none. If the branch doesn't exist, create it from main. Switch to it.

Each issue gets its own issue branch, `slice/<feature>/<issue>-<slug>`, where `<issue>` is the issue's number and `<slug>` a short kebab-case name from its title. If an issue branch already exists and the issue has a handoff note (see Hand off), resume it: check out that branch, read the note and carry on from where it left off. If the branch exists without a note, ask the user whether to resume it or start over.

## 3. One issue

- Read the issue's body: the behavior, the modules and the acceptance criteria.
- **Blockers**: run List issues and find this issue's blockers. If any is not done, name it and stop.
- **Amendments**: run Find approved. If one names this issue and has no issues yet, name it, tell the user to run `slice` and stop.
- Create the issue branch from the feature branch and switch to it, or check out the existing one to resume. State both branch names to the user.
- Set status to in progress through Set status.
- Run the Loop, then Merge. If the Loop stops at Red, tell the user and stop. If it stops at Green, run Stuck for this issue, tell the user and stop.

Then tell the user what merged: the issue, its commits and the feature branch, and whether it was pushed. Tell them to run `build` on the next ready issue or the parent, and to run `review` once every issue in the feature is done.

## 4. Several issues

You are the orchestrator. Stay on the feature branch in the main checkout, so each worker's worktree starts from it. Workers write code; you own the tracker and the merges.

- **Ready**: run List issues. An issue in the set is ready when it is open and every blocker is done. A blocker outside the set counts too. A blocked issue with a handoff note is ready again once every blocker is done; its worker resumes it. An issue an approved amendment names is not ready while that amendment has no issues.
- **Amendments**: run Find approved at the start and after each merge. When an approved amendment names an issue a worker is on, run Hand off for it.
- **Proposals**: when a worker reports a proposed amendment, tell the user in the session: the change, the reason and the issues it names. Only an amendment the user approves counts. If they approve it there, record it through Approve, run Hand off for each issue it names that a worker is on, and tell them to run `slice` to add its issues. Otherwise carry on.
- **Start**: for each ready issue, set status to in progress through Set status, then start one worker with the Agent tool: a regular subagent, not a fork, with `isolation: "worktree"`. Forks can't start further forks. Give it the worker prompt below. Start every ready issue at once; workers run in parallel.
- **Merge, one at a time**: when a worker reports done, run Merge on its branch. Finish one merge before starting the next, so each issue rebases onto everything merged before it.
- **Repeat**: after each merge, run List issues again and start any issue that is now ready.
- **Red passes**: when a worker reports a red test that passed before any code was written, stop all work. Start no new workers. Tell each running worker with SendMessage to stop and commit what it has on its issue branch. Merge nothing further, even workers that already reported done. Tell the user in the session straight away: the issue, the test, and that the spec or the slicing is wrong, so other slices may share the problem. Then give the summary.
- **Green stuck**: when a worker reports green still failing after 5 test runs, run Stuck for its issue. The other workers carry on.
- **Stop** when no worker is running and nothing is ready, then give the summary.

State the feature branch and each issue branch to the user as workers start.

### Worker prompt

A worker starts with none of this session's context. Its prompt carries:

- The issue: its number, title and full body.
- Where the spec is, and the approved amendments to read with it.
- The feature branch, and the issue branch name to use.
- The check command from `docs/agents/checks.md`.
- That `docs/agents/tracker.md` is the tracker file, and that it must follow its rules on where tracker files live. Local `.scratch/` lives only in the main checkout, never in a worktree.
- That it doesn't change issue status, merge or push. You do. The one exception is a hand-off.
- That if you tell it to stop, it commits what it has on its issue branch and reports back.
- That if you tell it to hand off, it stops and commits what it has, pushes its issue branch with `git push -u origin <issue branch>` unless `git remote` is empty, and leaves a handoff note through Comment: what's done, what's left and the issue branch. Then it reports back.
- That if it finds the spec wrong, it may propose an amendment through Amendments → Propose and name it in its report. It never acts on an amendment that isn't approved, and keeps to the spec as written.
- The Loop section of this skill, and the Commits section, copied in full.
- What to report back: the issue branch, the worktree path and the commits, or why it stopped.

Tell the worker to start by renaming its worktree's branch with `git branch -m <issue branch>`. If `git rev-parse HEAD` differs from `git rev-parse <feature branch>`, it stops and reports.

To resume a handed-off issue, also give the worker the handoff note. Tell it to start by checking out the issue branch instead, reading the note and carrying on from where it left off.

### Summary

End in the session with:

- **Merged**: each issue, its commits, and whether the feature branch was pushed.
- **Stopped**: if a red test passed before any code was written, the issue and test, and each worker stopped with the branch holding its work.
- **Handed off**: each issue stopped by an approved amendment, its branch, and the amendment issue it waits on.
- **Proposed**: each amendment a worker proposed, and whether the user approved it.
- **Blocked**: each issue not built, and why: which blocker isn't done, green still failing after 5 test runs with the branch and worktree holding its work, or a dependent of a stuck issue.
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
- Count each test run in Green. If tests still fail after 5 runs, stop: commit the work in progress and tell the user, or the orchestrator if you are a worker, what still fails.
- Run the full test suite, so nothing else broke.
- Commit.

### Refactor

- Clean up what you wrote: names, duplication, structure. Change no behavior.
- Run the tests again. They must still pass.
- Commit. If nothing needed cleaning up, say so and skip the commit.

## Stuck

For an issue whose green still fails after 5 test runs. This blocks the issue and everything that depends on it; the rest carries on.

- Set status to Blocked through Set status, and add a Comment saying green still fails after 5 test runs, what fails, and the issue branch holding the work. No issue blocks it, so link none and say so in the comment.
- Run List issues and find every issue that depends on it, directly or through other issues. Set each to Blocked through Set status, with a Comment naming the stuck issue. Each one already has a blocked-by link to the issue it depends on; add one only where it is missing.
- Never start these issues. Leave the stuck issue's branch and worktree in place.

## Hand off

For an issue a worker is on when an approved amendment names it. The issue waits for the amendment's issues, then resumes on the same branch.

- **Worker**: tell it with SendMessage to hand off. It stops, commits, pushes its issue branch and leaves a handoff note, as its prompt says.
- **Orchestrator**: once it reports, remove its worktree with `git worktree remove` and keep the branch. Set the issue to Blocked through Set status, blocked by each of the amendment's issues. If the amendment has no issues yet, link none and say so in the comment; slice adds the links.
- Merge nothing from a handed-off worker, even one that already reported done.

## Merge

For one issue, run this yourself. For several, the orchestrator runs it for each finished worker, one at a time, in that worker's worktree.

- Rebase the issue branch onto the latest feature branch. Resolve any conflicts and run the tests again.
- Run the check command from `docs/agents/checks.md`, from the root of the checkout the issue branch is in. If it fails, fix the cause, commit and run it again; as orchestrator, send the failure back to the worker with SendMessage to fix and commit. Never merge on a failing check. If it can't be made to pass, leave the issue in progress, tell the user (or list it under Problems) and move on. Check failures here don't count toward Green's 5 test runs.
- Once it passes, in the main checkout on the feature branch, merge the issue branch with `git merge --ff-only`. For a worker, remove its worktree with `git worktree remove`. Then delete the issue branch.
- **Push**: if `git remote` is empty, skip the push and say so. Otherwise push the feature branch: `git push -u origin <feature branch>` the first time, `git push` after. Never push to main.
- Run Tick criteria from `docs/agents/tracker.md` for the criteria the issue built, then set status to done through Set status.

## Commits

Match the repo's own conventions: read `git log` for the message style, and follow any commit rules in the agent file. Reference the issue in each message. Commit only on the issue branch, never on main.
