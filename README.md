# skills

These are the Claude Code skills I use to take a feature from a rough idea to a reviewed feature branch. Each step runs in its own session and hands off through a spec or a ticket, not through chat history, so no single session grows huge.

## The pipeline

| Skill | What it does |
| --- | --- |
| `setup` | Run once per repo. Records the issue tracker (GitLab, GitHub or local files), how status is tracked, and the check command. Only you can start it. |
| `align` | Interviews you, one question at a time with a recommended answer, until every decision is settled. |
| `spec` | Writes the decisions, rejected options, scope and testable acceptance criteria into a spec. The spec is frozen once written. |
| `slice` | Cuts the spec into vertical slices, each one working behavior end to end, with blocking links. You approve the cut. |
| `build` | Runs worker agents with red/green TDD and merges finished slices into the feature branch. |
| `review` | In a fresh session, checks the feature branch against each issue and the spec, and reports. It changes nothing. |

You approve twice: the ticket cut, and the merge of the feature branch into main. Agents never merge into main.

## Install

**Clone and link.** This is what I do on my own machine. Changes show up as soon as you pull.

```sh
git clone https://github.com/ordinaryindustries/skills.git
cd skills
scripts/link.sh
```

`link.sh` symlinks each skill folder into `~/.claude/skills` and skips any name that's already there, so it won't replace your own skills. The skills get bare names: `align`, `spec`, and so on.

**Plugin.** In Claude Code:

```
/plugin marketplace add ordinaryindustries/skills
/plugin install oi-skills@ordinaryindustries
```

Plugin skills are namespaced, so you get `oi-skills:align`, `oi-skills:spec`, and so on, and they never overwrite anything. Updates arrive when I bump `version` in `.claude-plugin/plugin.json`. Only `version` drives updates; there are no release tags.

## Use it

In each repo, run `setup` first. It writes a short section in `CLAUDE.md` (or `AGENTS.md`) and the details in `docs/agents/`. The other skills read those and tell you to run `setup` if they're missing. Then start new work with `align`.

## Credits

Made at [Ordinary Industries](https://ordinary.industries). Many of the ideas here, like grilling a plan before building it and cutting work into vertical slices, come from [Matt Pocock's skills](https://github.com/mattpocock/skills).

## License

MIT. See [LICENSE](LICENSE).
