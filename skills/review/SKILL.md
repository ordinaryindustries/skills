---
name: review
description: In a fresh session after build, diff the feature branch against the branch it was cut from and check each issue for completeness and correctness against its acceptance criteria, the spec and approved amendments, then report findings by issue, each marked must-fix or nit. Changes nothing. Use after build, when the user asks to review a feature, a parent or some issues.
---

Check the feature branch against each issue and the spec, so the user knows what is ready for main and what isn't.

Run this in a fresh session after build. Work only from the tracker, the spec and the branch, never from chat history.

Review changes nothing: no code edits, no commits, no issues, no tracker writes. The user decides which findings become new tickets.

## 1. Check

- **Config**: read `docs/agents/tracker.md`. If it is missing, tell the user to run `setup` and stop.
- **Input**: a parent, or a list of issues. If the user didn't name any, ask which. For a parent, its issues are its children from List issues.
- **Spec**: read the parent's spec and any approved amendments through Read the parent.
- **Issues**: run List issues for each issue's status, then read each issue's body: the behavior, the modules and the acceptance criteria. If any issue in the set is not done, name it and ask whether to review only the done ones.

## 2. Diff

- **Branch**: `feature/<feature>`, where `<feature>` is the parent's kebab-case name, or a short kebab-case name from its title if the tracker has none. If it doesn't exist, tell the user and stop.
- **Parent branch**: the branch the feature branch was cut from, normally main.
- Diff against the merge base, so only the feature's own changes show: `git diff main...feature/<feature>`. List its commits with `git log main..feature/<feature>`.
- **Map commits to issues**: build references the issue in each commit message. Group the commits, and the files they touch, by issue. A commit with no issue reference goes under Across issues.

Read files as they are on the feature branch with `git show feature/<feature>:<path>`. Don't switch branches.

## 3. Review each issue

For each issue, read its commits, the code they change and the tests they add.

- **Completeness**: every acceptance criterion is built, and has a test that checks that behavior. A criterion with no code, or code with no test, is must-fix.
- **Correctness**: bugs, missed edge cases, and departures from the spec or approved amendments. Check the issue's modules too: code it should have changed and didn't, or changes outside them it didn't need.

For a large feature, use a sub-agent per issue. Give it the issue's body, the spec and approved amendments, the branch names, its commits, and this step copied in full. Tell it to change nothing and to report findings in the format below.

Then look across the whole diff for what no single issue owns: conflicts between issues, spec criteria no issue covers, and commits with no issue reference.

## 4. Report

Group findings by issue, in issue order. Mark each one **must-fix** or **nit**:

- **must-fix**: a criterion not built or not tested, a bug, or a departure from the spec or an approved amendment.
- **nit**: anything that works but could be better: naming, clarity, a missing edge-case test that isn't in the criteria.

Give each finding the file and line on the feature branch and the reason.

```markdown
## <NN>: <behavior>

- **must-fix** `<path>:<line>`: <what's wrong and why>
- **nit** `<path>:<line>`: <what could be better and why>

## Across issues

- **must-fix** <finding that spans issues or concerns the spec, with file and line where there is one>
```

If an issue has no findings, say so under its heading. If nothing spans issues, say so under Across issues.

End by telling the user that review changed nothing and created no issues, that they decide which findings become new tickets, and to use `slice` or an amendment for anything they want built.
