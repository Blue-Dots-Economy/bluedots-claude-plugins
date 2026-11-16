# Blue Dots Claude Code plugins

Claude Code plugins for the Blue Dots Economy team.

## Install

In Claude Code:

```
/plugin marketplace add Blue-Dots-Economy/bluedots-claude-plugins
/plugin install bluedots-release-tools@bluedots
/plugin install bluedots-ticket-tools@bluedots
/plugin install bluedots-schema-tools@bluedots
```

To pick up new versions later, run `/plugin marketplace update bluedots`.

To try a local checkout instead, run `/plugin marketplace add <path to this repo>`.

## Plugins

### bluedots-release-tools

Write Blue Dots release PR descriptions and release pages.

| Skill | What it does |
|---|---|
| `release-pr-notes` | Drafts the description of a release or promotion PR (feature → develop, UAT fix into develop, develop → main, hotfix into `release/<sprint>`, plus a short body for the automated `sync: release/<sprint>` PRs) in the house format, from the PRs and the diff in the range. Shows the draft before it creates or edits a PR. |
| `release-page` | Drafts the release-wide notes page (`notes.md`) for a sprint candidate (`rcN`), release or hotfix (`hotfixN`) in bluedots-docs, merged from the per-repo component files CI pushed to the `release-notes/<tag>` branch. Commits it locally, never pushes. |

Both skills follow the release notes style guide in [bluedots-docs](https://github.com/Blue-Dots-Economy/bluedots-docs/blob/main/docs/release-notes-style.md) and use the GitHub CLI (`gh`), signed in.

### bluedots-ticket-tools

File Blue Dots tickets on the delivery board.

| Skill | What it does |
|---|---|
| `creating-bluedots-tickets` | Files a Story, Task or Bug in any Blue Dots repo. Collects the required details before drafting, then sets the epic label, issue type, parent (a Story for Tasks and Bugs) and the Project #1 fields: Epic, Category, Work Type, Sprint, Sprint Entry, and Story Points or Estimate. Dry-runs before it creates anything. |

The team's sprint-board rules ship with it in `references/sprint-board-guidelines.md`: Story Points table, parents, Work Type, assignees and credit, sprint close and sprint review.

Sprint review scripts ship in the skill's `scripts/` folder: `fetch_board.py` saves Project #1 to `board.json`, `sprint_checks.py` lists a sprint's gaps by repo, and `dev_credit.py` shows each person's points (by Story assignee and by share of Task days) and Task days.

It uses the GitHub CLI (`gh`), signed in with access to the org's Project #1, plus `jq`.

### bluedots-schema-tools

Turn a Blue Dots schema workbook (Excel) into `network.json` and the aggregator registration form schemas.

| Skill | What it does |
|---|---|
| `schema-from-sheet` | Reads the programme's schema workbook (profile sheets per domain, Aggregator Owner and Coordinator sheets, interaction rules, Domains) and builds `network.json`, the four aggregator registration form files, `aggregator.config.yaml` and, when the workbook lists deployments, `deployments.env`. Can also compare a workbook with an existing `network.json`. Every choice it makes is written to `decisions.md`. |

The files are written by the skill's scripts from the workbook, the decisions file and the templates in `references/`, never by hand. Golden tests in `tests/` rebuild Purple Dots (ALIMCO) and Blue Dots and check every file matches: `python3 tests/run_golden.py`.

It needs Python 3.9 or newer; the skill installs `openpyxl` if it is missing. Don't commit programme workbooks: they can hold real personal data in hidden sheets.

## License

MIT. See [LICENSE](LICENSE).
