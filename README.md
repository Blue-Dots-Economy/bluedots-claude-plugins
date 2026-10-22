# Blue Dots Claude Code plugins

Claude Code plugins for the Blue Dots Economy team.

## Install

In Claude Code:

```
/plugin marketplace add Blue-Dots-Economy/bluedots-claude-plugins
/plugin install bluedots-release-tools@bluedots
```

To try a local checkout instead, run `/plugin marketplace add <path to this repo>`.

## Plugins

### bluedots-release-tools

Write Blue Dots release PR descriptions and release pages.

| Skill | What it does |
|---|---|
| `release-pr-notes` | Drafts the description of a release or promotion PR (feature → develop, develop → main, hotfix → main) in the house format, from the PRs and the diff in the range. Shows the draft before it creates or edits a PR. |
| `release-page` | Drafts the release-wide notes page (`notes.md`) for a sprint release candidate in bluedots-docs, merged from the per-repo component files CI pushed to the `release-notes/<tag>` branch. Commits it locally, never pushes. |

Both skills follow the release notes style guide in [bluedots-docs](https://github.com/Blue-Dots-Economy/bluedots-docs/blob/main/docs/release-notes-style.md) and use the GitHub CLI (`gh`), signed in.

## License

MIT. See [LICENSE](LICENSE).
