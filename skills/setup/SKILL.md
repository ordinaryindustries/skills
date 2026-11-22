---
name: setup
description: Configure this repo for the align, spec, slice, build and review skills, recording its issue tracker, status mapping and check command. Run once per repo, and again to change the config.
disable-model-invocation: true
---

Record how this repo tracks work and checks code, so the other skills can follow it without naming a tracker.

Setup changes shared state. Write nothing until the user approves the draft.

## 1. Explore

Facts are yours to find. Never ask the user something the repo or tools can answer.

- **Existing config**: a setup section in `CLAUDE.md` or `AGENTS.md`, and `docs/agents/tracker.md` and `docs/agents/checks.md`. If any exist, this is a re-run. Start from the current values and ask only about what changes.
- **Remote**: `git remote -v`. A GitLab host means GitLab, `github.com` means GitHub, and no remote means local.
- **CI config**: `.gitlab-ci.yml` and `.github/workflows/*.yml`. Note the commands each job runs for lint, tests and build.
- **Project files**: `package.json` scripts, `Makefile`, `Package.swift`, `*.xcodeproj`, `pyproject.toml`, `manage.py`, and the like. Match them to the CI commands.
- **CLI**: whether `glab` or `gh` is installed and authenticated.
- **Tracker details**: run the "Explore" steps in the tracker file for the remote's platform: tier, Status field, existing status labels, the `agent` label.
- **MCP servers**: any connected tools for the tracker.

Use a sub-agent for anything broad.

## 2. Settle

Read the tracker file for each candidate tracker: `trackers/gitlab.md`, `trackers/github.md` or `trackers/local.md`, next to this file.

Ask one question at a time. Number each one, give it a short title, list the options briefly and give your recommendation in one sentence. Phrase it so "yes" accepts your recommendation. Wait for the answer before asking the next one. Skip any question the facts already answer, and state the fact instead.

Settle these in order:

1. **Tracker**: GitLab, GitHub or local. Recommend the one that matches the remote. Follow the tracker file's rules on unsupported setups.
2. **Status**: in progress and blocked each map to the richest option the repo has. In order, that is the native Status field, the repo's existing status labels, then default labels setup creates. The two states may map to different options. Done always means closing the issue.
3. **Check command**: one command that runs what CI runs, from the repo root. Recommend what you detected, chaining steps with `&&`. If there is no CI, recommend the project's own test command. Never write a script for it.
4. **MCP alternative**: ask only if a tracker MCP server is connected. Recommend recording it as the alternative. The CLI stays the default.

## 3. Draft

Show everything you would write, in full:

- The pointer section (template below), and which agent file it goes into.
- `docs/agents/tracker.md`: the chosen tracker file's template with this repo's values filled in.
- `docs/agents/checks.md` (template below).
- Each label you would create, with its color and description.
- Any other change the tracker file asks for, such as a `.gitignore` line.

Ask the user to approve. Revise and show the draft again until they do.

## 4. Write

- **Agent file**: use `CLAUDE.md` if it exists, else `AGENTS.md` if it exists, else create `CLAUDE.md`. Never create one when the other exists.
- **Pointer section**: put it between the `<!-- setup:start -->` and `<!-- setup:end -->` markers. On a re-run, replace only what lies between them. On a first run, append it to the end of the agent file.
- **`docs/agents/`**: setup owns `tracker.md` and `checks.md`. Overwrite those two and leave any other file alone.
- **Labels**: create only the ones that are missing. Never rename, recolor or delete an existing label.
- Don't commit. List the files you wrote so the user can review and commit them.

Then tell the user setup is done and that `align` starts new work.

## Tracker operations

Every tracker file's template covers these operations under these headings, so the other skills can rely on them. The other skills say "parent" and "issue" and look up each operation in `docs/agents/tracker.md`.

- **Create the parent**: create it with the spec as its content.
- **Read the parent**: read the spec, and any amendments with their state.
- **Create an issue**: a child of the parent, with its body, the `agent` label and blocked-by links to the issues it depends on.
- **Edit an issue**: replace an issue's title and body, and add or remove its blocked-by links.
- **List issues**: list the parent's issues, each with its status and blockers.
- **Set status**: in progress, blocked (also add the blocked-by link) and done (close the issue).
- **Tick criteria**: mark built acceptance criteria done in an issue's body, changing only the checkboxes.
- **Comment**: add a note to an issue, such as a worker's handoff note.
- **Amendments**: propose one as a comment on the parent, record the user's approval, and find approved amendments.
- **Close as pointless**: close an issue an amendment or re-slice made pointless, with a note saying why.

Configuration exists once `docs/agents/tracker.md` exists. Any skill that finds it missing tells the user to run `setup`, and does not configure anything itself.

## Templates

### Pointer section

```markdown
<!-- setup:start -->
## Agent workflow

Work moves through the align, spec, slice, build and review skills.

- Tracker: <GitLab | GitHub | Local>. How to manage parents, issues, status and amendments: `docs/agents/tracker.md`.
- Checks: `<check command>`. Run them before merging any slice. More detail: `docs/agents/checks.md`.

Read those files only when a task needs them.
<!-- setup:end -->
```

### `docs/agents/checks.md`

```markdown
# Checks

Run from the repo root:

    <check command>

It passes when it exits 0. It mirrors CI: <CI file and the jobs it runs, or "no CI; the project's own test command">.

A worker runs it after rebasing onto the feature branch and before merging. If it fails, the slice does not merge.
```
