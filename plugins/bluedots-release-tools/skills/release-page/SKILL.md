---
name: release-page
description: Draft the release-wide notes page (`notes.md`) for a Blue Dots sprint release candidate in bluedots-docs, merged from the per-repo component files that CI pushed. Use when asked to "write the release page", "write the release-wide notes", or when working on a `release-notes/<tag>` docs PR (for example `release-notes/202610-s1-rc1`) before it is merged.
---

# Release page

Writes `src/releases/<sprint>/<rc>/notes.md` in a `bluedots-docs` checkout. Each service repo's `create-release` workflow pushes one `components/<repo>.md` per repo onto the `release-notes/<tag>` branch; this skill merges them into one release-wide page. Merging that docs PR publishes the rc, so the page must be written first. An rc without `notes.md` shows "Release-wide notes not written yet."

## Hard rules

- **Write only `notes.md`.** Never edit, rename or delete anything under `components/`. Those files are CI-owned.
- **Never write an upgrade verdict.** No "safe to upgrade", "recommended", "must upgrade", "should upgrade", "low risk", "no risk", "upgrade now". Give the facts; readers decide.
- **Security changes: effect, never mechanism.** The repos are public. Keep a component's effect wording; never add header or cookie names, token handling, algorithms, attack names, or what was vulnerable.
- **Ask before overwriting.** If `notes.md` already exists, show the diff and wait for an explicit yes.
- **Commit, never push.** Pushing and merging the docs PR are the maintainer's calls.

## Steps

### 1. Check the checkout

Run in the `bluedots-docs` checkout (look for a sibling `bluedots-docs/` directory next to the current repo, or ask once):

```sh
git branch --show-current
```

The branch must be `release-notes/<tag>` and `<tag>` must match `^20[0-9]{4}-s[0-9]+-rc[0-9]+$`. Otherwise stop and say so; do not switch branches yourself. Split the tag into `<sprint>` (`YYYYMM-sN`) and `<rc>` (`rcN`): `202610-s1-rc2` is sprint `202610-s1`, rc `rc2`. The rc directory is `src/releases/<sprint>/<rc>/`. If `components/` there is missing or empty, stop: CI has not pushed yet.

### 2. Read the inputs

1. **Every component file:** `src/releases/<sprint>/<rc>/components/*.md`. Note each file's frontmatter `repo`, `previous_tag` and `notes_missing`, and its five sections (Release Notes, In Plain Terms, Breaking changes / config, What users will notice, Deploy ordering). Each file covers only that repo's changes since its `previous_tag`, so the page describes this rc's changes, not the whole sprint.
2. **The previous `notes.md`:** list them with `find src/releases -path '*/rc*/notes.md'` (a bare glob errors in zsh when there are none), take each one's tag from its path (`<sprint>-<rc>`), and pick the highest tag below `<tag>`. Order tags by sprint `YYYYMM`, then sprint number `N`, then rc number, all numeric (so `rc10` comes after `rc9`); this is `compareTags` in `src/lib/releases.mjs`. Use it for tone, theme labels and repeated deploy steps only. Do not copy its items; anything it already lists was released before. If there is none (the first release), skip this input.
3. **The style guide:** `docs/release-notes-style.md` in the same checkout. If it is missing, fetch it:

   ```sh
   gh api repos/Blue-Dots-Economy/bluedots-docs/contents/docs/release-notes-style.md -H 'Accept: application/vnd.github.raw'
   ```

   If neither works, continue with the Hard rules and step 3 and say in your reply that the guide could not be loaded. Where the guide and this skill disagree, the guide wins, except the Hard rules.

### 3. Write `notes.md`

Frontmatter is the tag only, quoted:

```md
---
tag: '<tag>'
---
```

Then these six headings, verbatim, in this order, at level 2. No `## Verification` or `## Checklist`; those belong to PRs. An empty section reads `None.` on its own line, written only after you checked every component.

1. `## Summary`: the first line is one sentence on its own that says what the release delivers, in plain words, without jargon and without "this release". The releases index shows this first line as the sprint's one-liner, so keep anything else in a second paragraph after a blank line: which repos cut the tag, and which carried no notes. 2 to 4 sentences in total, never `None.`.
2. `## Release Notes`: merge every component's bullets under shared bold theme labels, headline theme first. Rewrite each component's `(#N)` as `(Blue-Dots-Economy/<repo>#N)`, taking `<repo>` from that component's frontmatter, so links stay right on a page that spans repos. When two repos ship halves of one change, write one bullet and put both links on it. A component with `notes_missing: true` lists bare PR titles: keep each as a bullet (rewritten in plain words if the title is clear, otherwise as is) and name the repo in the Summary.
3. `## In Plain Terms`: one paragraph for the whole release, at most 4 sentences or about 80 words, headline change first. Combine the components' paragraphs; do not stack them. No PR numbers, env var names or jargon.
4. `## Breaking changes / config`: every item from every component, one bullet each, with its cross-repo PR link. If two repos list the same variable or migration, write one bullet that says which repos it affects.
5. `## What users will notice`: one bullet per visible change, deduplicated across repos. Quote UI strings exactly. `None.` and nothing else only when every component says `None.`.
6. `## Deploy ordering`: state the order across all repos in this rc explicitly, one bullet per constraint, naming the repo and PR on both sides with the reason in one clause. Two components often describe the same constraint from each side ("deploy before signals-search", "deploy after signals-dpg"): write it once. Also check the Breaking changes for an order the components did not spell out, such as a config or schema change in one repo that another repo reads. Write `None.` only when any order works.

Plain-language rules R1 to R8 in the checkout's `CLAUDE.md` apply to Summary, In Plain Terms, Breaking changes / config and What users will notice. Do not name internal files, branches or people.

### 4. Ask before overwriting

If `src/releases/<sprint>/<rc>/notes.md` already exists, someone may have edited it by hand. Write the draft to a temporary file, show

```sh
git diff --no-index src/releases/<sprint>/<rc>/notes.md <draft file>
```

and ask whether to overwrite. Lines marked `-` are in the current file and would be lost, often a hand edit; point them out. If the diff is empty, say the page is already up to date and stop. If the user says no, leave the file untouched and stop. If it does not exist, show the draft in a fenced `md` block and write it.

### 5. Check style and build

```sh
pnpm check:style
pnpm build
```

`pnpm check:style` scans `notes.md` (component files are exempt). Fix every hit in `notes.md`. A style or link failure outside `src/releases/` was there before you started; report it and leave it alone. `pnpm build` must pass, because the docs CI does not build PRs: if it fails, do not commit; fix `notes.md` if it is the cause, otherwise report the failure and stop. Also re-check by hand: the six headings in order, every Release Notes bullet ends with a PR link, and no verdict wording (search for "safe", "recommend", "risk", "upgrade" and judge each hit in context).

### 6. Commit, never push

```sh
git add src/releases/<sprint>/<rc>/notes.md
git commit -m "docs: release-wide notes for <tag>"
```

Stage only `notes.md`. Do not push; tell the user the commit is ready and that merging the `release-notes/<tag>` PR publishes the rc.
