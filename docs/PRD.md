# PRD: AI Development Workflow and Skills Repo

Nov 21, 2026 · Jack

## Overview

A five-skill pipeline takes a feature from idea to a reviewed feature branch: align, spec, slice, build, review. The skills are published in one public repo, branded as Jack's, so they install on any machine.

**Problem.** Planning and building in one long session grows the context and burns tokens. Splitting the work across sessions needs durable state between them.

**Goals**

- Settle every decision before any code is written.
- Keep state between sessions in the spec and the tickets, not in a chat.
- Build in vertical slices, so each finished ticket is a working feature end to end.
- Let agents write code with red/green TDD, commit, and merge into an feature branch.
- Install the skills on a new machine in a couple of commands.

**Non-goals**

- A separate planning step after the spec.
- A retro skill.
- Agents merging into main.

## The pipeline

Each skill runs in its own session and hands off through a file or a ticket, never through chat history.

| Skill | Input | Does | Output |
| --- | --- | --- | --- |
| align | A rough idea | Asks one question at a time, each with a recommended answer, until no decision is open | A conversation where the user and agent agree on everything |
| spec | The align conversation | Records decisions, rejected options, out of scope, testable acceptance criteria | A spec in the parent's description, or `.scratch/<feature>/spec.md` in local mode |
| slice | A spec, plus GitLab, GitHub or local mode | Cuts the work into vertical slices with blocking links; the user approves the cut | A parent with child issues, or files in `.scratch/<feature>/issues/` |
| build | A parent, an issue, or a list of issues | Runs worker subagents with red/green TDD, merges slices into the feature branch | A summary of what merged, what is blocked and why |
| review | A parent or issues | In a fresh session, checks the feature branch against each issue and the spec | A report; the user decides what becomes new tickets |

The user approves at two points: the ticket cut, and the merge of the feature branch into main.

## Specs and tickets

The spec is frozen once written; changes arrive only as amendments the user approves.

**Spec**

- Every feature gets a parent that holds the spec and has the slices as children. The skills only say "parent"; each tracker file maps it (see Skills repo).
- In tracker mode the spec lives in the parent's description. In local mode it is `.scratch/<feature>/spec.md`.
- The spec records the goal, decisions with reasons, rejected options, what is out of scope, and testable acceptance criteria.
- There is no planning step after the spec. By then the user and the agent already agree on the work.

**Amendments**

- Agents propose a change as a comment on the parent. It counts only once the user approves it.
- An approved amendment only adds new issues. Existing issues are never edited by an amendment; only a re-slice the user approves changes them (see Slicing).
- The amendment names the issues it affects, checked against each issue's module list.
- A worker on an affected issue stops, commits, pushes its branch and leaves a handoff note. A fresh worker resumes it once the amendment issue is done.
- If the amendment makes an issue pointless, the issue is closed and its branch deleted.

**Slicing**

- Each slice is one user-visible behavior, built end to end through every module it touches. Never one slice per layer or module.
- Slices are tracer bullets. Slice 01 is the thinnest real, kept path through every layer the feature touches; if the codebase already has one, that path is the tracer. Each later slice widens it by one behavior.
- Each slice is named as a behavior, lists its modules and acceptance criteria, and has blocking links to the slices it depends on.
- The user approves the cut before any work starts.

**Re-slicing**

- When the parent already has issues, slice shows them and offers to keep them, update them, or re-slice from scratch, with a recommendation. The user decides.
- Done issues are never changed. In-progress and blocked issues change only if the user says so.
- Nothing changes until the user approves the plan. Closed issues are closed as pointless, with a note naming the re-slice. The spec stays frozen.

## Implementation and orchestration

build runs a worker per ready issue, and the AI merges finished slices into the feature branch; only the user merges into main.

**Orchestration**

- One issue needs a single agent. A whole spec or several issues need an orchestrator and worker subagents.
- Start the orchestrator as a skill. Move the mechanical parts into a script later, once the loop stops changing: dependency graph, worktrees, serial merge, labels.
- An issue is ready when every blocker is done. Each worker gets its own worktree branched from the feature branch.
- The orchestrator owns the tracker and the merges: it sets status, merges slices one at a time, and pushes. Workers only write code.
- Current Claude Code lets subagents start their own subagents, and the Agent tool can isolate a subagent in its own worktree. Forks cannot start further forks, so workers are regular subagents.

**Worker loop**

1. Red: write a failing test for each acceptance criterion, then commit.
2. Green: implement until the tests pass, then commit.
3. Refactor, then commit.
4. Merge, one slice at a time: rebase onto the latest feature branch, run the local checks, merge, push the feature branch, tick the issue's acceptance criteria, mark the issue done. With no remote, the push is skipped. Nothing is ever pushed to main.

Local checks run the same tooling as CI, so there is no separate CI gate. Workers may change their own tests; there is no test lock.

**When a worker gets stuck**

| Case | What stops | Why |
| --- | --- | --- |
| Red test passes before any code is written | All work stops; the user is told in the session | The spec or the slicing is wrong, and other slices may share the problem |
| Green still failing after 5 test runs | That issue and its dependents | One hard slice, not a wrong plan |

**Summary**

When the orchestrator finishes or runs out of ready work, it reports in the session: what merged, what is blocked and why, and any problems. Issues are not assigned to the user.

## Review

review is a separate skill the user runs after build, in a fresh session; it is not part of the worker loop.

- It diffs the feature branch against its parent.
- For each issue, it checks completeness (every acceptance criterion built and tested) and correctness (bugs, missed edge cases, departures from the spec).
- It reports findings by issue, each marked must-fix or nit, and changes nothing.
- The user decides which findings become new tickets.

## Skills repo

The generic skills live in one public GitLab repo, mirrored to GitHub, installable as a Claude Code plugin.

**Audience.** The public, plus Jack on his own machines.

**What goes where**

- Generic skills: the public repo.
- Project-specific skills: each project's `.claude/skills`, so they travel with the code.
- Personal skills tied to no project: a small private repo.

**Layout**

```
ordinaryindustries/ai/skills
├── .claude-plugin/
│   ├── marketplace.json      # one plugin, source "./"
│   └── plugin.json           # name, version, author
├── skills/
│   ├── setup/
│   │   ├── SKILL.md
│   │   └── trackers/
│   │       ├── gitlab.md
│   │       ├── github.md
│   │       └── local.md
│   ├── align/SKILL.md
│   ├── spec/SKILL.md
│   ├── slice/SKILL.md
│   ├── build/SKILL.md
│   └── review/SKILL.md
├── scripts/
│   └── link.sh               # symlinks each skill into ~/.claude/skills
├── LICENSE
└── README.md
```

**Per-project setup.** Run `setup` once per repo. Only the user can start it (`disable-model-invocation: true`); other skills that find no config tell the user to run it.

1. Explore the repo: remote, CI config, project files, existing labels, connected MCP servers.
2. Settle the tracker, status mapping and check command, one question at a time, each with a recommendation.
3. Draft everything: the CLAUDE.md section, each `docs/agents/` file, and any labels it would create. Write nothing until the user approves.
4. Write. A re-run updates setup's own section and files in place and leaves the rest alone.

Output:

- A short pointer section in the repo's agent file: `CLAUDE.md` if it exists, else `AGENTS.md` if it exists, else a new `CLAUDE.md`. Never create one when the other exists.
- The details in `docs/agents/*.md`, including the chosen tracker's how-to. Skills read them only when needed, so the agent file stays small.
- The check command, detected from the CI config and project files and confirmed by the user. Setup does not create a script.

The other skills never name a tracker; they follow `docs/agents/`.

**Status**

- Always use the built-in state: close an issue when it is done, after ticking its acceptance criteria in the body.
- For in progress and blocked, use the richest option the repo has, in this order: the native Status field (GitLab Premium and Ultimate, or a GitHub Project), the repo's existing status labels, then default labels setup creates (`status::` on GitLab, `status:` on GitHub). Blocked also gets the platform's blocking link.
- On GitHub, labels are flat: adding a new status label means removing the old one.
- Every issue the agents manage also gets an `agent` label.

**Trackers**

| Tracker | Parent | Access |
| --- | --- | --- |
| GitLab, Premium and Ultimate | An epic | `glab`; Status through `glab api graphql`, since `glab` cannot set it |
| GitHub | A parent issue with sub-issues and issue dependencies | `gh` v2.94 or later |
| Local | The `.scratch/<feature>/` folder, not committed | Files |

The CLI is the default. If setup finds a connected MCP server for the tracker, it records that as the alternative. GitLab's free tier is out of scope; its users can edit the skills.

**Install**

|  | Jack's main machine | Other machines and the public |
| --- | --- | --- |
| How | Clone, run `link.sh` | `/plugin marketplace add <url>`, then `/plugin install` |
| Skill names | `align` | `oi-skills:align` |
| Changes arrive | At once | When `version` is bumped |

`link.sh` links each skill folder on its own and skips any name already present, so it never replaces a user's own skills. Plugin skills are namespaced and never overwrite anything. Skills refer to each other by bare name only.

**Releases.** Only the `version` field in `plugin.json` controls updates. No tags.

**Hosting.** GitLab is the source. A GitLab push mirror keeps a read-only GitHub copy, so the public gets the short install form.

**License.** MIT. Anything adapted from Matt Pocock's skills keeps his copyright notice and MIT text; ideas taken without his text owe nothing, though he is credited.

**Naming.** The repo sits in the OI group and the plugin prefix is `oi-skills`. Everything people see is branded as Jack's: the README, its voice and the posts. The README credits Ordinary Industries.

## Rejected options and open items

These were considered and dropped; they are recorded so later sessions don't reopen them.

| Option | Why it was dropped |
| --- | --- |
| A planning step after the spec | The spec already settles the work |
| A living spec any agent can edit | The reviewer needs a stable spec to check against |
| Re-slicing existing issues after an amendment | Rewrites reviewed work; amendments only add issues. Re-slicing happens only in slice, with the user's approval |
| slice refusing to run when the parent has issues | The user should be offered an update or re-slice and make the call |
| A reviewer inside the worker loop, capped at 3 rounds | Replaced by a separate review skill run after build |
| A CI gate before each slice merge | Local checks run the same tooling as CI |
| A test lock after the red commit, enforced by a script | Not wanted |
| Assigning blocked issues to the user | The session summary is enough |
| A retro skill | Dropped |
| Release tags | `version` alone drives updates; tags add sync work |
| GitLab-only hosting | Discovery happens on GitHub, so it is mirrored |
| Symlinking the whole skills folder | Would replace a user's own skills |
| Setup config inline in CLAUDE.md | Loaded into every session; pointer files keep it small |
| MCP-only tracker access | Not portable |
| Separate `ai::` status labels | Two status systems drift apart |
| Labels as the only status | They don't move an issue through the platform |
| Committed spec folders | `.scratch/` preferred |
| Epics as a required concept | GitHub has none; skills say "parent" instead |
| Letting Claude start setup on its own | It changes shared state |

**Open items**

- [ ] Confirm whether the desktop app's "Add marketplace" form accepts GitLab URLs. One third-party guide says it doesn't; install from Claude Code if so.
- [ ] Decide when the orchestrator's mechanical parts move from the skill into a script.
- [ ] Write the setup skill and its three tracker files first, since every other skill reads what setup writes.
