# Local tracker

Work is tracked in files under `.scratch/`, which is never committed. Use it when the repo has no remote, or when the user wants no tracker.

## Explore

- Check whether `.gitignore` already ignores `.scratch/`.
- Check for existing `.scratch/*/` folders. Leave them as they are.

## Setup rules

- Status is the `status` field in each issue file, so there are no labels to create and no status question to ask. State this instead of asking.
- If `.gitignore` doesn't ignore `.scratch/`, include adding a `.scratch/` line in the draft.

## Template

Copy everything below the line into `docs/agents/tracker.md`.

---

# Tracker: Local

Each feature lives in `.scratch/<feature>/`, where `<feature>` is a short kebab-case name. The folder is ignored by git, so it never reaches main or a feature branch.

```
.scratch/<feature>/
├── spec.md          # the parent
├── amendments/
│   └── NN-<slug>.md
└── issues/
    └── NN-<slug>.md
```

Worktrees don't share `.scratch/`. Always read and write it in the main checkout, at `$(git rev-parse --path-format=absolute --git-common-dir)/..`, never inside a worktree.

## Create the parent

Write the spec to `.scratch/<feature>/spec.md`. The folder is the parent.

## Read the parent

Read `spec.md`, then every file in `amendments/`.

## Create an issue

Number issues from `01` in dependency order, so every issue's blockers come before it. Write `issues/NN-<slug>.md`:

```markdown
---
status: open
labels: [agent]
blocked_by: []
---

# NN: <behavior>

<body>

## Notes
```

- `status` is one of `open`, `in-progress`, `blocked`, `done` or `closed`.
- `blocked_by` lists the numbers of the issues it depends on, such as `[01, 03]`.

## Edit an issue

Rewrite the `# NN: <behavior>` heading and the body, leaving `## Notes` as it is. Add or remove numbers in `blocked_by`.

## List issues

Read the front matter of every file in `issues/`. An issue is ready when it is `open` and every issue in its `blocked_by` is `done`.

## Set status

Edit the `status` field and nothing else.

- **In progress**: `in-progress`.
- **Blocked**: `blocked`. Add the blocking issue's number to `blocked_by` if it isn't already there, then add a note saying why.
- **Done**: `done`.

## Tick criteria

Change `- [ ]` to `- [x]` in the body for each criterion that was built. Change only the checkbox characters, never the wording.

## Comment

Append a bullet under `## Notes`: `- <YYYY-MM-DD> <author>: <note>`. Apart from notes, the body changes after the issue is created only through Edit an issue and Tick criteria.

## Amendments

- **Propose**: write `amendments/NN-<slug>.md` with `status: proposed` in its front matter. Give the change, the reason and the numbers of the issues it affects.
- **Approve**: once the user approves it in the session, set `status: approved` and add `approved: <YYYY-MM-DD>`.
- **Find approved**: list the amendments whose status is `approved`.

## Close as pointless

Set `status: closed` and add a note naming the amendment or re-slice that made the issue pointless.
