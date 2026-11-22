# GitLab tracker

For GitLab Premium and Ultimate. The parent is an epic in the project's group, and slices are its child issues. Access is through `glab`, mostly `glab api graphql`, since epics, Status and blocking links are work-item features.

## Explore

Run these from the repo. `<group>` is the group the project sits in directly, where its epics live. Ask which ancestor group to use only if the user keeps epics higher up.

- `glab auth status` succeeds for the remote's host.
- Project and group paths: `glab repo view -F json` (`path_with_namespace`). The group is everything before the last `/`.
- The Epic type, which the group only offers on Premium and Ultimate:

  ```sh
  glab api graphql -f query='query($p: ID!) { namespace(fullPath: $p) {
    workItemTypes(onlyAvailable: true, name: EPIC) { nodes { id name } } } }' -f p=<group>
  ```

- The Issue type and the Status field's statuses:

  ```sh
  glab api graphql -f query='query($p: ID!) { project(fullPath: $p) {
    workItemTypes(name: ISSUE) { nodes { id name widgetDefinitions { type
      ... on WorkItemWidgetDefinitionStatus { allowedStatuses { id name category } } } } } } }' -f p=<project>
  ```

  If the Epic query returns no node, or Issue lists no `allowedStatuses`, treat the group as free tier.
- Existing labels, with their GIDs:

  ```sh
  glab api graphql -f query='query($p: ID!) { project(fullPath: $p) {
    labels(first: 100, includeAncestorGroups: true) { nodes { id title } } } }' -f p=<project>
  ```

  Look for `agent` and any status labels, such as `status::in progress` or `status::blocked`.
- A connected GitLab MCP server.

## Setup rules

- **Free tier**: unsupported. Tell the user the GitLab skills need Premium or Ultimate, and recommend local mode instead.
- **Status, per state**: use a native status whose category or name matches (`in_progress` for in progress, a status named like "Blocked" for blocked). Failing that, use an existing status label. Failing that, create `status::in progress` or `status::blocked`. GitLab's default statuses have no Blocked, so blocked usually maps to a label.
- **Labels**: create `agent` and any default status labels at the group level if missing, so every project in the group shares them. `glab label create` only makes project labels, so use the API: `glab api groups/<url-encoded group>/labels -f name=<name> -f color=<color> -f description=<description>`. Then look up their GIDs again.
- Record every GID the template needs. Other skills must never have to look one up.

## Template

Copy everything below the line into `docs/agents/tracker.md`, filling in each `<placeholder>`. Drop the status lines that don't apply.

---

# Tracker: GitLab

The parent is an epic in `<group>`, and each slice is a child issue in `<project>`. Use `glab`. Work items take global IDs (GIDs), so run these through `glab api graphql`.

| Name | Value |
| --- | --- |
| Group | `<group>` |
| Project | `<project>` |
| Epic type | `<gid://gitlab/WorkItems::Type/…>` |
| Issue type | `<gid://gitlab/WorkItems::Type/…>` |
| `agent` label | `<gid://gitlab/…Label/…>` |
| In progress | Status `<name>` (`<status GID>`) or label `<name>` (`<label GID>`) |
| Blocked | Status `<name>` (`<status GID>`) or label `<name>` (`<label GID>`) |
| Won't do | Status `<canceled status GID>`, or none |
| MCP alternative | `<server name>`, or none |

Use the CLI. Use the MCP server only if `glab` is unavailable.

**GID from an IID.** An epic: `glab api graphql -f query='query($p: ID!, $i: String!) { group(fullPath: $p) { workItem(iid: $i) { id } } }' -f p=<group> -f i=<iid>`. An issue: `glab api graphql -f query='query($p: ID!, $i: [String!]) { project(fullPath: $p) { workItems(iids: $i) { nodes { id } } } }' -f p=<project> -f i=<iid>`.

Queries take plain variables with `-f`. Mutations build a JSON body with `jq` and pipe it to `glab api graphql -H 'Content-Type: application/json' --input -`; without that header GitLab rejects the body. Every mutation returns `errors` on failure. Check for it.

## Create the parent

```sh
jq -n --rawfile d spec.md '{query: "mutation($in: WorkItemCreateInput!) { workItemCreate(input: $in) { workItem { id iid webUrl } errors } }",
  variables: {in: {namespacePath: "<group>", workItemTypeId: "<epic type>", title: "<feature>", description: $d,
    labelsWidget: {labelIds: ["<agent label>"]}}}}' \
| glab api graphql -H 'Content-Type: application/json' --input -
```

## Read the parent

```sh
glab api graphql -f query='query($p: ID!, $i: String!) { group(fullPath: $p) { workItem(iid: $i) {
  id title description webUrl
  widgets { ... on WorkItemWidgetNotes { discussions(first: 100) { nodes { id
    notes { nodes { id body author { username } createdAt } } } } } } } } }' -f p=<group> -f i=<epic iid>
```

The description is the spec. Amendments are discussions on the epic (see Amendments).

## Create an issue

```sh
jq -n --rawfile d body.md '{query: "mutation($in: WorkItemCreateInput!) { workItemCreate(input: $in) { workItem { id iid webUrl } errors } }",
  variables: {in: {namespacePath: "<project>", workItemTypeId: "<issue type>", title: "<behavior>", description: $d,
    hierarchyWidget: {parentId: "<epic GID>"},
    labelsWidget: {labelIds: ["<agent label>"]},
    linkedItemsWidget: {linkType: "BLOCKED_BY", workItemsIds: ["<blocker GID>"]}}}}' \
| glab api graphql -H 'Content-Type: application/json' --input -
```

Create blockers first so their GIDs exist. Leave out `linkedItemsWidget` when nothing blocks the issue.

## Edit an issue

Replace the title and body:

```sh
jq -n --rawfile d body.md '{query: "mutation($in: WorkItemUpdateInput!) { workItemUpdate(input: $in) { errors } }",
  variables: {in: {id: "<issue GID>", title: "<behavior>", descriptionWidget: {description: $d}}}}' \
| glab api graphql -H 'Content-Type: application/json' --input -
```

Add a blocked-by link with the `workItemAddLinkedItems` call under Set status. Remove one:

```sh
jq -n '{query: "mutation($in: WorkItemRemoveLinkedItemsInput!) { workItemRemoveLinkedItems(input: $in) { errors } }",
  variables: {in: {id: "<issue GID>", workItemsIds: ["<blocker GID>"]}}}' \
| glab api graphql -H 'Content-Type: application/json' --input -
```

## List issues

```sh
glab api graphql -f query='query($p: ID!, $i: String!) { group(fullPath: $p) { workItem(iid: $i) {
  widgets { ... on WorkItemWidgetHierarchy { children(first: 100) { nodes { id iid title state webUrl
    widgets {
      ... on WorkItemWidgetStatus { status { name } }
      ... on WorkItemWidgetLabels { labels { nodes { title } } }
      ... on WorkItemWidgetLinkedItems { linkedItems { nodes { linkType workItemState workItem { iid } } } }
    } } } } } } } }' -f p=<group> -f i=<epic iid>
```

An issue is ready when it is open, not in progress or blocked, and every `BLOCKED_BY` item is closed.

## Set status

For a native status, set `statusWidget`. For a label, use `labelsWidget`. Setting one state clears the other.

```sh
jq -n '{query: "mutation($in: WorkItemUpdateInput!) { workItemUpdate(input: $in) { errors } }",
  variables: {in: {id: "<issue GID>", statusWidget: {status: "<status GID>"}}}}' \
| glab api graphql -H 'Content-Type: application/json' --input -
```

For a label, replace `statusWidget` with `labelsWidget: {addLabelIds: ["<label GID>"], removeLabelIds: ["<other status label GID>"]}`.

- **In progress**: set the in-progress status or label.
- **Blocked**: set the blocked status or label, then add the link and a comment saying why:

  ```sh
  jq -n '{query: "mutation($in: WorkItemAddLinkedItemsInput!) { workItemAddLinkedItems(input: $in) { errors } }",
    variables: {in: {id: "<issue GID>", linkType: "BLOCKED_BY", workItemsIds: ["<blocker GID>"]}}}' \
  | glab api graphql -H 'Content-Type: application/json' --input -
  ```

- **Done**: remove any status label, then close the issue with `glab issue close <iid> -R <project>`. Closing moves the native Status to Done.

## Tick criteria

Read the description into `body.md`, change `- [ ]` to `- [x]` there for each criterion that was built, then write it back. Change only the checkbox characters, never the wording.

```sh
glab api graphql -f query='query($p: ID!, $i: [String!]) { project(fullPath: $p) { workItems(iids: $i) { nodes { description } } } }' \
  -f p=<project> -f i=<iid> | jq -r '.data.project.workItems.nodes[0].description' > body.md
jq -n --rawfile d body.md '{query: "mutation($in: WorkItemUpdateInput!) { workItemUpdate(input: $in) { errors } }",
  variables: {in: {id: "<issue GID>", descriptionWidget: {description: $d}}}}' \
| glab api graphql -H 'Content-Type: application/json' --input -
```

## Comment

On an issue: `glab issue note <iid> -R <project> -m "<note>"`.

## Amendments

- **Propose**: start a discussion on the epic. Make its first line `**Amendment: <title>**`, then give the change, the reason and the issues it affects as `#<iid>` references.

  ```sh
  glab api graphql -f query='mutation($id: NoteableID!, $b: String!) { createNote(input: { noteableId: $id, body: $b }) {
    note { id discussion { id } } errors } }' -f id=<epic GID> -f b="$(cat amendment.md)"
  ```

- **Approve**: once the user approves it in the session, reply in the same discussion, passing `discussionId: <discussion GID>` to `createNote`, with the body `**Approved** by the user on <YYYY-MM-DD>.`
- **Find approved**: run Read the parent and keep the discussions whose first note starts with `**Amendment:` and that have a reply starting with `**Approved**`.

## Close as pointless

Comment naming the amendment or re-slice that made the issue pointless, then close the issue with the native `Won't do` status if there is one:

```sh
jq -n '{query: "mutation($in: WorkItemUpdateInput!) { workItemUpdate(input: $in) { errors } }",
  variables: {in: {id: "<issue GID>", stateEvent: "CLOSE", statusWidget: {status: "<canceled status GID>"}}}}' \
| glab api graphql -H 'Content-Type: application/json' --input -
```

Without a native Status field, run `glab issue close <iid> -R <project>`.
