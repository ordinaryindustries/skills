# GitHub tracker

The parent is an issue, slices are its sub-issues, and blocking uses issue dependencies. Access is through `gh` v2.94 or later.

## Explore

- `gh --version` is 2.94 or later, and `gh auth status` succeeds. If not, tell the user to upgrade or log in, and stop.
- `gh issue create --help` and `gh issue edit --help`: check for native flags for a parent issue or blocked-by. Where they exist, write them into the template in place of the `gh api` calls.
- Repo: `gh repo view --json nameWithOwner,owner`.
- Linked Projects: `gh project list --owner <owner> --format json`. For a Project the repo's issues live in, `gh project field-list <number> --owner <owner> --format json` gives the Status field's ID and its options. Projects need the `project` scope; if a call is refused, ask the user to run `gh auth refresh -s project`.
- Existing labels: `gh label list --limit 200 --json name`. Look for `agent` and any status labels.
- A connected GitHub MCP server.

## Setup rules

- **Status, per state**: use a Project Status option that matches ("In progress", "Blocked"). Failing that, use an existing status label. Failing that, create `status: in progress` or `status: blocked`. If more than one Project fits, use the one that holds most of the repo's open issues; ask only if that doesn't single one out.
- **Labels**: create `agent` and any default status labels if missing: `gh label create "<name>" --color <hex> --description "<description>"`.
- Record every ID the template needs: Project number, Project node ID, Status field ID and option IDs. Other skills must never have to look one up.

## Template

Copy everything below the line into `docs/agents/tracker.md`, filling in each `<placeholder>`. Drop the lines that don't apply.

---

# Tracker: GitHub

The parent is an issue in `<owner>/<repo>`, and each slice is a sub-issue of it. Blocking uses issue dependencies. Use `gh`, run from the repo, so `{owner}/{repo}` in `gh api` paths fills itself in.

| Name | Value |
| --- | --- |
| Repo | `<owner>/<repo>` |
| Project | `<number>` (node ID `<PVT_…>`), or none |
| Status field | `<PVTSSF_…>`, or none |
| In progress | Project option `<name>` (`<option ID>`) or label `<name>` |
| Blocked | Project option `<name>` (`<option ID>`) or label `<name>` |
| MCP alternative | `<server name>`, or none |

Use the CLI. Use the MCP server only if `gh` is unavailable.

Sub-issue and dependency endpoints take the issue's REST `id`, not its number: `gh api repos/{owner}/{repo}/issues/<number> --jq .id`.

## Create the parent

```sh
gh issue create --title "<feature>" --body-file spec.md --label agent
```

## Read the parent

```sh
gh issue view <number> --json title,body,url,comments
```

The body is the spec. Amendments are comments (see Amendments).

## Create an issue

```sh
gh issue create --title "<behavior>" --body-file body.md --label agent
gh api repos/{owner}/{repo}/issues/<parent number>/sub_issues -F sub_issue_id=<new issue id>
gh api repos/{owner}/{repo}/issues/<new number>/dependencies/blocked_by -F issue_id=<blocker id>
```

Create blockers first so their IDs exist. Add one `blocked_by` call per blocker. If a Project is in use, add the issue to it: `gh project item-add <project number> --owner <owner> --url <issue url>`.

## Edit an issue

```sh
gh issue edit <number> --title "<behavior>" --body-file body.md
```

Add a dependency with the `blocked_by` call under Create an issue. Remove one:

```sh
gh api -X DELETE repos/{owner}/{repo}/issues/<number>/dependencies/blocked_by/<blocker id>
```

## List issues

```sh
gh api repos/{owner}/{repo}/issues/<parent number>/sub_issues --paginate \
  --jq '.[] | {number, title, state, labels: [.labels[].name]}'
gh api repos/{owner}/{repo}/issues/<number>/dependencies/blocked_by --jq '.[] | {number, state}'
```

With a Project, read each issue's Status with `gh issue view <number> --json projectItems`. An issue is ready when it is open, not in progress or blocked, and every blocker is closed.

## Set status

Labels are flat on GitHub, so adding a status label means removing the other one:

```sh
gh issue edit <number> --add-label "<new status label>" --remove-label "<old status label>"
```

For a Project option, find the issue's item ID with `gh project item-list <project number> --owner <owner> --format json`, then:

```sh
gh project item-edit --id <item ID> --project-id <project node ID> --field-id <status field ID> --single-select-option-id <option ID>
```

- **In progress**: set the in-progress option or label.
- **Blocked**: set the blocked option or label, add the dependency with the `blocked_by` call above, and comment saying why.
- **Done**: remove any status label, then `gh issue close <number> --reason completed`.

## Tick criteria

Read the body into `body.md`, change `- [ ]` to `- [x]` there for each criterion that was built, then write it back. Change only the checkbox characters, never the wording.

```sh
gh issue view <number> --json body --jq .body > body.md
gh issue edit <number> --body-file body.md
```

## Comment

```sh
gh issue comment <number> --body "<note>"
```

## Amendments

- **Propose**: comment on the parent. Make the first line `**Amendment: <title>**`, then give the change, the reason and the issues it affects as `#<number>` references.
- **Approve**: once the user approves it in the session, comment on the parent `**Approved**: Amendment: <title>, by the user on <YYYY-MM-DD>.`
- **Find approved**: run Read the parent and keep the amendments whose title appears in an `**Approved**` comment.

## Close as pointless

```sh
gh issue close <number> --reason "not planned" --comment "Made pointless by <reason>."
```

`<reason>` is `Amendment: <title>` or `the re-slice on <YYYY-MM-DD>`.
