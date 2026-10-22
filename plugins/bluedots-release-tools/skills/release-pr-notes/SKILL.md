---
name: release-pr-notes
description: Write the description for a Blue Dots release or promotion pull request in the house format (Summary, Release Notes, In Plain Terms, Breaking changes / config, What users will notice, Deploy ordering, Verification, Checklist). Use when opening or updating a promotion PR (feature → develop, develop → main), a hotfix PR into main, or when asked to "write release notes" or "write the release PR description" for a Blue Dots repo, including "as of tag <sprint tag>".
---

# Release PR notes

Writes the body of a release or promotion PR in a Blue Dots repo (signals-dpg, aggregator-dpg, signals-search, notification-service, bluedots-automation and the rest of the `Blue-Dots-Economy` org). The docs site copies five of its sections into the public release page, so the headings and the rules below are a contract, not a suggestion.

## Hard rules

- **Never write an upgrade verdict.** No "safe to upgrade", "recommended", "must upgrade", "should upgrade", "low risk", "no risk", "upgrade now". Give the facts; readers decide.
- **Show the draft before any write.** Never run `gh pr create` or `gh pr edit` until the user has read the draft and said yes.
- **Security changes: effect, never mechanism.** The repos are public. Say what is now better ("sign-in sessions are harder to misuse"). Leave out header and cookie names, token handling, algorithms, attack names (SSRF, CSRF, XSS and so on), what was vulnerable, and how it could be exploited.
- **Every Release Notes bullet ends with a PR link** `(#N)`, `(#N, #M)`, or `(owner/repo#N)` for another repo.
- **All eight headings, verbatim, in this order, at level 2.** An empty section reads `None.` on its own line, written only after you checked.

## Steps

### 1. Load the style guide

The style guide is the source of truth. Fetch it:

```sh
gh api repos/Blue-Dots-Economy/bluedots-docs/contents/docs/release-notes-style.md -H 'Accept: application/vnd.github.raw'
```

If that fails (404, offline, no `gh` auth), read `docs/release-notes-style.md` from a local `bluedots-docs` checkout if the user has one (look for a sibling `bluedots-docs/` directory next to the current repo, or ask once). If neither is available, continue with the Hard rules above and step 6 and say in your reply that the guide could not be loaded. Where the guide and this skill disagree, the guide wins, except the Hard rules.

### 2. Read the repo's PR template

Read `.github/PULL_REQUEST_TEMPLATE.md` in the target repo (locally, or `gh api repos/<owner>/<repo>/contents/.github/PULL_REQUEST_TEMPLATE.md -H 'Accept: application/vnd.github.raw'`). Its checklist items go, ticked as appropriate, into `## Checklist`. Its `## Summary` and `## Release Notes` match ours; the other six headings are added on top of it.

### 3. Work out the range

Take the range from the user if given. Otherwise infer it:

| PR kind | base | head | range |
|---|---|---|---|
| feature → develop | `develop` | `feature` | `origin/develop..origin/feature` |
| develop → main | `main` | `develop` | `origin/main..origin/develop` |
| hotfix → main | `main` | hotfix branch | `origin/main..origin/<hotfix branch>` |
| "as of tag `<T>`" | previous sprint tag | `<T>` | `<previous tag>..<T>` |

When the user gives both a PR kind and a tag (for example "develop → main as of `202609-s1-rc2`"), the tag bounds the range (`<previous tag>..<T>`) and the PR kind only decides the base of the PR you will open or edit.

- Sprint tags match `^20[0-9]{4}-s[0-9]+-rc[0-9]+$` and are cut from `main`. The previous tag is the highest sprint tag below `<T>` in that order (sprint, then rc). Ignore suffixed tags (`-alimco`, `-hotfix`, `-up-dhwd` and so on): never use one as the previous tag.
- Run `git fetch origin --tags` first in a local checkout. Without a checkout, use `gh api repos/<owner>/<repo>/compare/<base>...<head>`.

### 4. Collect the PRs in the range

1. List the commits: `git log --format='%h %s' <base>..<head>` and `git log --merges --format='%h %s' <base>..<head>`.
   - Squash merges end their subject with `(#N)`; merge commits read `Merge pull request #N from ...`. A subject can also carry an issue number, such as `fix: ... (#685) (#686)`; check each number with `gh pr view <N>` and link only pull requests.
   - **Drop** promotion PRs (head branch `feature` or `develop`, such as an earlier feature → develop PR) and sync-down merges (`merge: sync main into develop` and similar). Their content is already in the underlying PRs or was released before. Say in the Summary what you left out and why, for example a direct-to-main fix that was already released.
2. Get the details of the PRs. Which branches to list depends on the range:

   | Range | List merged PRs with |
   |---|---|
   | feature → develop | `--base feature` |
   | develop → main | `--base feature` and `--base develop` |
   | tag-bounded (`<previous tag>..<T>`) | `--base feature`, `--base develop` and `--base main` |
   | hotfix → main | none: `gh pr view <hotfix PR number>`, plus any PR numbers from step 1 via `gh pr view` |

   ```sh
   gh pr list --base <branch> --state merged --limit 200 \
     --json number,title,body,labels,files,mergedAt,headRefName
   ```

   Keep only the PR numbers found in step 1, so a PR merged into one of those branches before or after the range is never listed. For a tag-bounded range without a local checkout, take step 1's commit list from `gh api --paginate repos/<owner>/<repo>/compare/<previous tag>...<T> --jq '.commits[].commit.message'`. Promotion PRs into `main` are still dropped as in step 1; a fix merged straight into `main` inside the range is kept. Fetch anything still missing directly: `gh pr view <N> --json number,title,body,labels,files`.
3. Read every PR body in full. The `## Release Notes`, `## In Plain Terms`, deploy notes, "must ship first", "depends on", migration and realm notes are where the facts are. A PR labelled `no-release-notes` goes only into a Housekeeping bullet.

### 5. Scan the diff for config signals

`## Breaking changes / config` is backed by this scan, not by memory.

```sh
git diff --name-only <base>...<head> | grep -Ei '(^|/)\.env|config|values[^/]*\.ya?ml$|(^|/)drizzle/|network\.json$|openapi\.json$'
```

(Without a checkout, use the `files[].filename` list from the compare API; it caps at 300 files, so fall back to each PR's `files` if the range is larger.)

For every hit, read the diff (`git diff <base>...<head> -- <path>`) and decide:

- new, renamed or removed environment variables, and changed defaults;
- feature flags and modes (for example a `*_MODE` switch) and the order in which they may be turned on;
- database migrations (`drizzle/**`) and what they change;
- `network.json` or schema changes;
- `openapi.json`: removed or renamed routes and fields, and changed status codes;
- Helm `values*.yaml` changes that operators must mirror;
- also any behaviour a caller depended on that now changes, even without a config file (for example a kind of request that is now refused).

Template-only edits that need no action (for example placeholders in an example env file) stay out of this section. When unsure, list the item.

### 6. Write the body

Use these headings, exactly, in this order. Follow `references/example-release-pr.md` (next to this file) for shape and level of detail.

1. `## Summary`: for the reviewing engineer. What the promotion contains, the merge method if it matters (promotions into `develop` and `main` are merge commits, not squash), and what is left out. 2 to 4 sentences, never `None.`.
2. `## Release Notes`: one bullet per user- or operator-facing change, grouped under bold theme labels (`**Sign-in and sessions**`, `**Search and discovery**`, `**Security**`, `**Housekeeping**`), headline theme first. One or two sentences per bullet; rewrite PR titles, do not paste them. Fold refactors, dependency batches and CI fixes into one Housekeeping bullet. Every bullet ends with its PR link(s). Never `None.` when PRs merged.
3. `## In Plain Terms`: for a PM or a non-technical reader. One paragraph, at most 4 sentences or about 80 words, headline change first. No PR numbers, env var names, jargon or hype words ("major", "exciting").
4. `## Breaking changes / config`: for whoever deploys. One bullet per item from step 5: the name, what it does, the default, what to do, and the PR link.
5. `## What users will notice`: for a trainer or PM. One short bullet per visible change, in the words users see; quote UI strings exactly as the PR shows them. No PR numbers or technical terms. `None.` and nothing else when nothing visible changed.
6. `## Deploy ordering`: one bullet per order constraint, naming the repo and PR on both sides, with the reason in one clause. Look for these in PR bodies ("must ship first", "depends on", "merge order"). `None.` only when any order works.
7. `## Verification`: green checks on the promoted HEAD (short SHA and check names), ancestry (`main` is contained in `develop`), manual checks. If nothing was verified, say what was not.
8. `## Checklist`: the PR template's items, ticked, plus the merge instruction (`--merge`, not `--squash`, for promotions; do not delete the head branch) and the reminder to cut the shared release tag after all repos land.

Plain-language rules for sections 3, 4 and 5: short sentences, concrete nouns, active voice, expand an acronym on first use. Use `Blue Dots`, `a blue dot`, `domain` and `participant type`. Do not name internal files, branches or people in the five published sections (Release Notes, In Plain Terms, Breaking changes / config, What users will notice, Deploy ordering).

### 7. Check the draft

Before showing it, confirm:

- all eight headings are present, verbatim and in order;
- every bullet under `## Release Notes` (bold theme labels aside) ends with a PR link;
- no verdict wording anywhere (search for "safe", "recommend", "risk", "should upgrade", "must upgrade", then judge each hit in context: "keeps your sign-in more safely" describes a change, "safe to upgrade" is a verdict);
- no security mechanism detail (header or cookie names, algorithms, attack names);
- every config-scan hit from step 5 is listed under `## Breaking changes / config` or deliberately left out because it needs no action.

### 8. Show the draft and wait

Print the full body in a fenced `md` block and ask whether to use it. Only after an explicit yes, write it to a temporary file and run `gh pr create --base <base> --head <head> --title "<title>" --body-file <file>` (or `gh pr edit <N> --body-file <file>` for an existing PR). For the title, follow the repo's recent promotion PRs, for example `release: develop → main (YYYY-MM-DD)`.
