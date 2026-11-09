# Sprint board guidelines

**[Project #1](https://github.com/orgs/Blue-Dots-Economy/projects/1) is the single source of truth.**
- Update it directly, not the sprint sheet.
- Fill every field when you create the ticket.

Filing tickets with Claude Code: install the **bluedots-ticket-tools** plugin, which applies these rules for you.

```
/plugin marketplace add Blue-Dots-Economy/bluedots-claude-plugins
/plugin install bluedots-ticket-tools@bluedots
```

## Creating a ticket

1. **Check before creating:** search for an existing ticket first.
2. **Type:** Story, Task or Bug.
   - A Story should take about 2–3 days.
   - **Need an Epic? Talk to the program lead.**
3. **Parent:**
   - **A Story's parent is an Epic.** Pick it from [bluedots-program](https://github.com/Blue-Dots-Economy/bluedots-program/issues) or from [the current sprint's Epics](https://github.com/orgs/Blue-Dots-Economy/projects/1/views/26). Epics created in the code repos (such as the sprint's "Implementation Epic for <sprint>") are added to the sprint and kept up to date. If nothing fits, talk to the program lead.
   - **A Task or Bug's parent is a Story.** Pick it from [the current sprint's Stories](https://github.com/orgs/Blue-Dots-Economy/projects/1/views/12). If no Story fits, create the Story first.
4. **Sizing:**
   - **Only Stories carry Story Points.** Tasks and Bugs carry **Estimate (d)** in dev days.
   - A Story's points cover its Tasks and Bugs. Don't add their estimates on top.
   - Use the table below to turn days into points.
5. **Title and description:** plain, simple and descriptive.
   - No internal codes.
   - No personal data.
6. **Also set:** assignee, Epic, Category, Sprint, Work Type and Sprint Entry.

## Story Points

| Dev days | ≤ 0.5 | 1 | 1.5–2 | 3 | 4–5 | 6–10 |
|---|---|---|---|---|---|---|
| **Story Points** | 1 | 2 | 3 | 5 | 8 | 13 |

- More than 10 days (two weeks) is too big for one Story: split it.
- Points are a range, not an exact sum. A Story's points only need to be close to its Tasks' and Bugs' estimates.

## Category

| | Use for | Example |
|---|---|---|
| **FN** Functional | Something a user can see or use | Invite aggregators, multi-language UI |
| **TE** Technical | Platform engineering with no new user capability: refactors, performance, schemas, security, compliance, tech debt | Keycloak cutover, Maps compliance |
| **OP** Operational | Releases, deployments, infra, deployment support, data fixes, CI, adopter docs | Release roll-out, client data clean-up |
| **DE** Design | Design or specification before building | Localisation data design |

- **A support request that needs a code change** is an OP Task for the request plus an FN or TE ticket for the change.
- **A bug** takes the category of the feature it breaks.

## Work Type: take the first match

1. Fixing a defect → **Bug** (a Bug ticket is always Work Type Bug)
2. Time-boxed investigation or support, with findings as the outcome → **Spike**
3. Agreed at sprint planning → **Planned**
4. Unplanned OP support request → **Chore**
5. Unplanned FN, TE or DE request → **Interrupt**

In client emails, Interrupt, Chore and Bug are called **"Requests"**.

## Sprint and Sprint Entry

- **Sprint:** set it on every ticket worked on in the sprint. Leave it **empty for backlog** tickets.
- **Sprint Entry:**
  - **New** the first time a ticket is in a sprint, including old backlog tickets.
  - **Carried-forward** for the ticket that continues unfinished work from the previous sprint.

## Operational support Stories (OP only)

For requests that keep coming through the sprint (each client deployment, production):
1. **At planning:** create one Story per deployment per sprint, e.g. "<deployment> support 202610-s1", **with no points**.
2. **During the sprint:** log each request as its own Task under that Story, with **only an estimate**.
3. **At sprint close:** add up the Tasks' dev days and set the Story's points from the Story Points table.

Every other Story gets its points at planning.

## Sprint close

**A ticket stays in the sprint it was worked in.** Don't change the Sprint field of a ticket that was worked in a closed sprint, because the sprint's history and reports depend on it.

For each ticket that is still open at close:

| Case | The old ticket | The remaining work |
|---|---|---|
| **Done** | Close it as completed. | — |
| **Partly done** | Re-size it to the part that was done, then close it as completed. | A new ticket in the next sprint: same parent, Sprint Entry **Carried-forward**, Carry Count = old count + 1, Slip Reason, and a link to the old ticket. |
| **Not started, continues** | Close it as not planned, with a comment linking the new ticket. | A new ticket in the next sprint, set up as above. |
| **Not started, back to backlog** | Clear Sprint and Sprint Entry, and fill Slip Reason. It stays open. | — |

**Stories with Tasks and Bugs:**
- Done Tasks and Bugs stay under a Story in the sprint they were done in.
- Open Tasks and Bugs move to a Story in the next sprint (a new one if needed), or to the backlog with no Sprint.
- If a backlog Story has a Task that was done in a sprint, move that Task under a Story in that sprint.
- Tasks found while working on a Story (for example clean-up follow-ups) belong to the sprint they are worked in. Give them a Story in that sprint, and leave the original Story closed in its own sprint.

**Support Stories:** set their points from the Tasks' days (see above), then close them.

## Reviewing a sprint

When checking a sprint for gaps:
- **Leave out tickets closed as not planned or duplicate**, both as Stories and as Tasks or Bugs.
- Leave out the Epics in bluedots-program. Epics in code repos are fine.
- Story Points versus the Tasks' and Bugs' estimates is a range. Only flag a Story whose estimates are far from its points.
- Check that:
  - every Story has an Epic as parent, and every Task and Bug has a Story;
  - every Story has points and no estimate;
  - every Task and Bug has an estimate and no points;
  - Epics have neither points nor an estimate;
  - Bugs have Work Type Bug, and Sprint, Sprint Entry, Work Type, Epic, Category and assignee are set.

## Always

- **Link every PR to its issue** with `Closes #N`, and link the issue in Development.
