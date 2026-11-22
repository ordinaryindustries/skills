---
name: slice
description: Cut a frozen spec into vertical-slice issues, each one user-visible behavior with its modules, acceptance criteria and blockers, and create them once the user approves the cut. Use after spec, when the user asks to slice the work, create the issues, add the issues for an approved amendment, or re-slice a parent that already has them.
---

Cut the spec on a parent into vertical slices, so build can take each one through to a working feature.

The spec is frozen. Read it, never edit it. Nothing is created or changed until the user approves the cut.

## 1. Check

- **Config**: read `docs/agents/tracker.md`. If it is missing, tell the user to run `setup` and stop.
- **Input**: a parent. If the user didn't name one, ask which. Read its spec and any approved amendments through Read the parent.
- **Amendments**: run Find approved. An amendment has issues once an issue's body names it. If an approved amendment has none yet, follow Amendment below for it instead of Existing issues, unless the user asked to re-slice.
- **Existing issues**: run List issues. If the parent already has issues, follow Existing issues below.

## 2. Explore

Facts are yours to find. Read the codebase to learn which modules each behavior in the spec touches: the files, components or layers it runs through, and whether a path the feature extends already runs end to end. Use a sub-agent for anything broad. Never ask the user something the code can answer.

## 3. Cut

- **One behavior per slice**: each slice is one thing a user can see or do, built end to end through every module it touches. Never cut one slice per layer or module, such as "the model", "the API", "the UI".
- **Tracer bullet first**: slice `01` is the tracer bullet, the thinnest path that runs end to end through every layer the feature touches. It is real, kept, production-quality code, not a throwaway prototype, and it proves the pieces connect. If step 2 found that the feature extends a path that already runs end to end, that path is the tracer and every slice widens it.
- **Widen one behavior at a time**: each later slice widens the path by one behavior, and is itself a thin end-to-end path.
- **Name it as a behavior**: what the user or system does, such as "User resets a forgotten password", not "Password reset service".
- **Modules**: list every module the slice touches.
- **Acceptance criteria**: take them from the spec. Every spec criterion lands in at least one slice. Split a broad one into the parts each slice builds, but add nothing the spec doesn't say.
- **Blockers**: the slices that must be done before this one can be built. Keep them to real dependencies, so slices can run in parallel.
- **Order**: number the slices from `01` in dependency order, so every slice's blockers come before it.

Keep slices small enough for one worker to finish, and large enough that each one works on its own.

## 4. Approve

Show the whole cut as a table, marking the tracer bullet, then each slice's criteria. If an existing path is the tracer, name it above the table instead.

| # | Slice | Modules | Blocked by |
| --- | --- | --- | --- |
| 01 | <behavior> (tracer bullet) | `<module>` | none |
| 02 | <behavior> | `<module>`, `<module>` | 01 |

Then list any spec criterion that no slice covers, or say that every one is covered. Ask the user to approve. Revise and show the cut again until they do.

## 5. Create

- Create the issues in order, blockers first, so every blocking link points at an issue that already exists. Use Create an issue in `docs/agents/tracker.md` for each, with the `agent` label and a blocked-by link to each of its blockers. Use the body template below.
- If the operation reads the body from a file, write it to a temporary file outside the repo.
- Don't commit.

Then give the user each issue's link or path, and tell them to run `build`.

## Amendment

An approved amendment only adds new issues. It never edits an existing one; only a re-slice does that.

- **Cut**: run steps 2 and 3 for the amendment's change alone. The feature's existing path is the tracer, and each new issue widens it. Take the acceptance criteria from the amendment, and add a line naming it to each body (see the template).
- **Affected**: the issues the amendment names. Each one that isn't done gets a blocked-by link to every new issue, added through the blocking link in Edit an issue. Leave its body as it is.
- **Pointless**: an issue the amendment makes pointless is closed instead. If it was in progress, ask the user first.
- **Approve**: show the new issues as in step 4, with the links to add and the issues to close. Nothing is created or changed until the user approves.
- **Apply**: Create an issue for each new one, numbered after the existing ones, blockers first as in step 5. Then add the links. Close each pointless issue with Close as pointless, naming the amendment, and delete its issue branch if one exists: remove any worktree holding it, run `git branch -D`, and `git push origin --delete` if it is on the remote.

Then give the user each new issue's link or path, and tell them to run `build`.

## Existing issues

Show the parent's issues with their status. Offer three choices and recommend one, with the reason. The user has the final say.

- **Keep**: leave them as they are. Stop and tell the user to run `build`.
- **Update**: cut again against the spec (steps 2 and 3), then show a plan that marks each existing issue as keep, edit (with what changes) or close, plus any new issues.
- **Re-slice**: close the open issues that haven't started, and propose a fresh cut (steps 2 and 3).

For update and re-slice:

- Never change a `done` issue. Flag any in-progress or blocked issue, and change it only if the user explicitly says so.
- Show the plan as in step 4. Nothing changes until the user approves it.
- Apply it with Edit an issue for each edit, Close as pointless for each close with a note naming the re-slice, and Create an issue for each new one, blockers first as in step 5. Number new issues after the existing ones.
- The spec stays frozen. Re-slicing never edits it.

## Template

```markdown
Spec: <parent link or path>.
Amendment: <amendment link, path or title>. (Only on an issue an amendment adds.)

**Behavior.** <what the user sees or does, end to end, in a sentence or two>

**Modules**

- `<module>`

**Acceptance criteria**

- [ ] <one observable, testable behavior>
```
