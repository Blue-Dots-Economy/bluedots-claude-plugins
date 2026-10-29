---
name: creating-bluedots-tickets
description: Use when creating, filing, raising or opening any GitHub issue in the Blue-Dots-Economy org — a story, task, bug, epic or sub-epic in signals-dpg, aggregator-dpg, signals-search, notification-service, bluedots-automation, ai-diffusion-dpg, bluedots-e2e, bluedots-schemas, bluedots-docs, bluedots-infra-deployments or keycloak-otp-authenticator. Triggers on "add a ticket", "raise a bug", "create an issue", "new story", "new epic", "add a task in <repo>", or breaking work down into tickets — even if the user doesn't say "skill".
---

# Creating Blue Dots tickets

Epics live in `Blue-Dots-Economy/bluedots-program` (private, **zero commits — issues only**). Tickets live in the repo whose code changes. Everything lands on org **Project #1 "Blue Dots — Delivery"**, which is the single source of truth: fill every field when the ticket is created.

This skill restates the team's sprint-board guidelines. Taxonomy: `program-ops/02-epic-taxonomy.md` in bluedots-program.

## Ticket types and parents

| Type | Size | Parent | Sizing field |
|---|---|---|---|
| **Story** | about 2–3 days | an epic (or sub-epic) in bluedots-program | **Story Points**: 1, 2, 3, 5, 8, 13 |
| **Task** | a piece of a Story | **a Story** (any repo), never an epic | **Estimate (d)** in dev days |
| **Bug** | a defect fix | **a Story** (any repo), never an epic | **Estimate (d)** in dev days |

- Only these three types. **A new Epic or sub-epic needs the program lead's approval** (see the end of this file).
- **Choosing a parent:** first [Project #1 view 26](https://github.com/orgs/Blue-Dots-Economy/projects/1/views/26); if nothing fits, the bluedots-program issues; if nothing fits there either, ask the program lead. A Task or Bug with no fitting Story gets a new Story created first.
- One parent only (GitHub allows one).

## The gate: collect required details BEFORE drafting

**You may not write an issue body until you have the REQUIRED details.** Ask for the missing ones in one batch, then draft.

| Ticket | REQUIRED before you draft |
|---|---|
| **All** | repo; epic code; parent; one-line outcome in the user's words; **Work Type**; assignee; Sprint (or "backlog") |
| **Story** | outcome; what is in and out of scope; done-when; **Story Points** (none only for an OP support Story) |
| **Task** | the concrete change; the file/service/surface it touches; done-when; **Estimate (d)** |
| **Bug** | observed behaviour; expected behaviour; where seen (env/instance/URL); repro steps *as the reporter experienced them*; severity; **Estimate (d)** |

**Never invent these — ask, or write `_TBD_`:** root cause, reproduction steps, acceptance criteria, scope, priority, estimate, story points, assignee, sprint.

`_TBD_` is always better than a plausible guess. A guessed root cause in a bug body sends someone down the wrong path for a day. Drafting first and listing "questions I would have asked" at the end is the failure this gate exists to prevent: the user edits what you wrote instead of saying what they meant.

### Rationalizations — all of these mean STOP and ask

| Excuse | Reality |
|---|---|
| "None of this blocked me from drafting" | The draft *is* the problem. Anchoring beats asking. |
| "I made the most reasonable call on each" | You picked one of several readings and hid the choice. |
| "It's a small task, I'll attach it to the epic" | Tasks and Bugs go under a Story. Find or create one. |
| "Estimates and points are planning, leave them" | The guidelines require them at creation. Ask. |
| "I'll flag the assumptions at the end" | Trailing caveats don't get read. The body does. |
| "I found a checklist in a related issue to flesh out" | That's someone else's scope. |

## Field rules

**Work Type — take the first match:**
1. Fixing a defect → **Bug** (a Bug ticket is always Work Type Bug)
2. Time-boxed investigation or support, findings as the outcome → **Spike**
3. Agreed at sprint planning → **Planned**
4. Unplanned OP support request → **Chore**
5. Unplanned FN, TE or DE request → **Interrupt**

**Category** follows the epic prefix: `FN-` Functional (something a user can see or use), `TE-` Technical (refactors, performance, schemas, security, compliance, tech debt), `OP-` Operational (releases, deployments, infra, support, data fixes, CI, adopter docs), `DE-` Design. Two rules decide the epic, and so the category:
- **A bug** takes the epic and category of the feature it breaks.
- **A support request that needs a code change** is an OP Task for the request plus an FN or TE ticket for the change.

**Sprint / Sprint Entry:** set Sprint on every ticket worked on in a sprint; leave it **empty for backlog**. Sprint Entry is **New** the first time a ticket is in a sprint (including old backlog tickets), **Carried-forward** if it was unfinished in the previous sprint (then also Carry Count +1 and Slip Reason).

**Title and body:** plain and descriptive, for someone who never worked on it. **No internal codes** (plan or finding IDs such as `D1`, `F29`, `[NS][S1]`) and **no personal data** — the code repos are public.

## OP support Stories

For requests that keep arriving through a sprint (each client deployment, production):
1. **At planning:** one Story per deployment per sprint, e.g. "<deployment> support 202610-s1", **no Story Points**.
2. **During the sprint:** each request is its own Task under that Story, Work Type Chore, **estimate only**.
3. **At sprint close:** add up the Tasks' dev days and set the Story's points: ≤0.5 → 1, ≤1 → 2, ≤1.5 → 3, ≤2.5 → 5, ≤4 → 8, >4 → 13.

## Filing

**Step 0 — duplicate check (always, before asking):**
```bash
gh issue list -R Blue-Dots-Economy/<repo> --state all --limit 40 --search "<keywords>" \
  --json number,title,state,createdAt
```
Also check bluedots-program for an epic that already covers it. If a close match exists, propose commenting on or re-labelling it instead.

**Then one command applies every binding** (epic label, issue type, parent, board Epic/Category/Work Type/Sprint/Sprint Entry/points or estimate). Run it with `--dry-run` first and show the user the plan:

```bash
bash <this skill's directory>/scripts/file_ticket.sh \
  --repo signals-dpg --type Bug --epic FN-NOTIFY --work-type Bug \
  --parent 844 --estimate 1 --assignee <login> \
  --title "…" --body-file /tmp/body.md        # --sprint "<option>" if in a sprint
```

The script refuses a Task or Bug without a Story parent (`--parent-repo` for a Story in another repo), Story Points on a Task or Bug, an estimate on a Story, a Bug whose Work Type is not Bug, and Sprint values the board doesn't have. It warns when assignee, estimate or points are missing. It works when the board's auto-add rule has already added the issue.

**Leaf rule:** with nested epics use the leaf only (`epic:FN-AI-REACH`, never `FN-AI` *and* `FN-AI-REACH`).

**PRs:** link every PR to its issue with `Closes #N`, and link the issue in the PR's Development panel.

## Creating a new epic or sub-epic (program lead's approval first)

1. Issue in `bluedots-program`, title `[<CODE>] <Name>`, `--type Epic`, labels `epic:<CODE>` + `cat:<category>`, body using the standard block (Owner / Category / Release table + the `program-ops/02-epic-taxonomy.md` pointer — copy the shape from bluedots-program#26).
2. For a **sub-epic**, create it by hand and link it to its parent epic: `gh api repos/.../bluedots-program/issues/<parent>/sub_issues -X POST -F sub_issue_id=<its REST id>`.
3. Create the `epic:<CODE>` label in every repo that will carry children (`--color 1f6feb` FN, `6e7681` TE, `8957e5` OP; pick one for DE when its first epic is created).
4. Add the code as an option on the board's **Epic** field with `bash <this skill's directory>/scripts/add_epic_option.sh`, which preserves existing option IDs. Editing options without their IDs **clears the field on all 1000+ items**.

Sub-epics exist when a parent hits GitHub's **100 sub-issue cap** (why FN-AI split into CORE/REACH/TRUST/MEMORY/KNOW) or for a separable workstream. FN-IAM is near the cap and will need the same split.

## Epic codes

Categories are **FN, TE, OP and DE** only.

`FN-` IAM, CONSENT, NOTIFY, ONBOARD, BULK, DISCOVER, ENGAGE, SUPPORT, DPDP, ACCESS, AI (→ AI-CORE, AI-REACH, AI-TRUST, AI-MEMORY, AI-KNOW), DEVKIT
`TE-` PLATFORM, SCHEMA, PERF, DATA, OBS, DEBT, AUDIT, HARDEN
`OP-` INFRA, LAUNCH, QA, DEVEX, DOCS
`DE-` check the board's Epic options.

The board's Epic options are the source of truth:
```bash
gh project field-list 1 --owner Blue-Dots-Economy --format json -L 50 -q '.fields[]|select(.name=="Epic")|.options[].name'
gh issue list -R Blue-Dots-Economy/bluedots-program --state open --limit 50 \
  --json number,title -q '.[] | "\(.title|capture("\\[(?<c>[A-Z-]+)\\]").c)=\(.number)"' | sort
```

## Legacy conventions — don't propagate

- `type:epic` / `type:feature` / `type:task` **labels** and the `Feature` issue type are superseded by Story/Task/Bug issue types.
- aggregator-dpg's `.github/ISSUE_TEMPLATE/*.md` still say to open epics in-repo; ignore them.
- **Project #3 is retired.** Project #1 is the only board.
- Repo-local `area:*` and `est:*` labels are still current.
