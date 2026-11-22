---
name: spec
description: Turn a settled align conversation into a frozen spec on a new parent, with the goal, decisions, rejected options, out of scope and testable acceptance criteria. Use after align, when the user asks to write the spec.
---

Record what align settled as a spec on a new parent, so later sessions work from it instead of the chat.

The spec is frozen once written. Changes arrive only as amendments the user approves, through the Amendments operation in `docs/agents/tracker.md`. Never edit the parent's spec after it is created.

## 1. Check

- **Config**: read `docs/agents/tracker.md`. If it is missing, tell the user to run `setup` and stop.
- **Input**: the align conversation in this session, ending in its summary. If there is none, tell the user to run `align` first and stop.
- **Open decisions**: if any remain, list them and tell the user to settle them with `align` first. Don't decide them yourself.

## 2. Draft

Write the spec from the conversation, using the template below. Add nothing the user didn't agree to.

- **Goal**: what the feature does and why, in a sentence or two.
- **Decisions**: each one, with its reason.
- **Rejected**: each option considered, with why it lost.
- **Out of scope**: what was explicitly excluded.
- **Acceptance criteria**: each one a single observable behavior a test can check. Rewrite vague ones until they are testable, or ask the user.

Pick a short title for the parent, and a short kebab-case name if the tracker asks for one.

Show the user the title and the full spec. Ask them to approve. Revise and show the draft again until they do.

## 3. Write

- Create the parent with the approved spec as its content, following Create the parent in `docs/agents/tracker.md`. If the operation reads the spec from a file, write it to a temporary file outside the repo.
- Don't commit.

Then give the user the parent's link or path, remind them the spec is now frozen, and tell them to run `slice`.

## Template

```markdown
## Goal

<what the feature does and why>

## Decisions

- **<decision>**: <reason>

## Rejected

- **<option>**: <why it lost>

## Out of scope

- <excluded item>

## Acceptance criteria

- [ ] <one observable, testable behavior>
```
