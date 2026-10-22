<!--
Worked example of a house-quality release PR description.
Source: signals-dpg #717 (develop -> main, released as tag 202609-s1-rc2), sanitised.
Security changes are described by their effect only; the repos are public.
Copy the shape and the level of detail, not the content.
-->

## Summary

Release promotion `develop` → `main` (16 commits, 214 files). **Merge commit, not squash**, so that `main ⊆ develop ⊆ feature` still holds.

Everything here has already been through `feature` → `develop` (#716) and is green on `develop`. The consent-version work from #693 is not listed: it went straight to `main` and is already released.

## Release Notes

**Sign-in and sessions**
- Sign-in sessions in the web app are now harder to misuse. Sign-in, renewal and sign-out are handled by the server. (#690)
- A sign-in that starts in another app now names the aggregator account correctly. (#688)
- When the server reports that a session has ended, the app signs the user out instead of retrying into a dead session. (#686)

**Security**
- Actions sent between instances are now verified. The example environment files now carry placeholders only. (#687)
- Outbound calls, a public lookup, a schema refresh and responses that carry personal data are now better protected against misuse. (#666)

**Search and discovery**
- The list view pages through the whole network, with an explicit sort order, a single domain control, and a card metric that matches the order. (#665, Blue-Dots-Economy/signals-search#152)
- The location-source switch stays put on the map view. (#691)
- Item cards can be opened from the keyboard. (#658)

**Housekeeping**
- Cleared half of the reliability backlog from code analysis, plus a mail-catcher health check fix and the weekly dependency batch for 2026-09-11. (#689, #705, #709)

## In Plain Terms

The biggest change is that the site now keeps your sign-in more safely. Separately, instances of the system now check who they are talking to, and the list of results now has a proper "sort by" control instead of guessing the order.

## Breaking changes / config

- `PEER_AUTH_MODE`: when set to `enforced`, instances refuse action requests from other instances that are not verified. This release adds the verification (#687). Do not set `PEER_AUTH_MODE=enforced` until this release is running on every instance; bluedots-automation #127 sets it in production.
- With Keycloak as the sign-in provider, browser sign-in now goes through the server. Scripts that called the API with a person's browser sign-in stop working. Service integrations using API keys or service accounts are unaffected. (#690)
- Keycloak realm: the realm file is imported only once, so on an existing realm add the API's sign-in callback URL to the `signals-ui` client's redirect URIs and the API origin to its post-logout redirect URIs before deploying. The realm file gains an `API_BASE_URL` placeholder that defaults to `PUBLIC_BASE_URL`. (#690)
- The list view's location filter now defaults to "Anywhere". Earlier, a signed-in user with a location silently saw only items within 30 km. No environment variables changed. (#665)

## What users will notice

- Everyone who is signed in is signed out once when this release is deployed. Nothing is lost; they sign in again.
- Signing in looks the same. After about 30 minutes without activity you are signed out, and the app takes you back to sign in instead of showing errors.
- The list view shows items from the whole network by default. Pick a radius under Location to narrow it.
- A new sort control sets the order of the list: relevance, newest, or nearest.
- The "All" tab is gone. Choose a domain above the results; the list takes one domain, the map takes several.
- The number on each card matches the sort: a relevance percentage, a distance, or an age.
- The map now has the same switch as the list for using your profile address or your current location.
- The map has a "Search this area" button when searching the visible area would change the results.

## Deploy ordering

- Deploy this repo before bluedots-automation #127, because #127 sets `PEER_AUTH_MODE=enforced`, which rejects traffic between instances until the verification from #687 is running.
- Deploy the API and the web app in the same window, API first, because the web app's new sign-in flow calls routes that only the new API has. (#690)
- Deploy bluedots-automation #210 before or together with this repo, because the new server-side sign-in (#690) needs the fixed Keycloak hostname or sessions end within minutes.
- Merge Blue-Dots-Economy/signals-search#152 before this repo (#665), because the new list view sends sort and area options that only that version understands.

## Verification

- `develop` HEAD `bebd1c71` is green: test, typecheck-api, typecheck-ui, build (api + ui), dep-cruise, schema-parity, spec-drift, sonar, SonarCloud.
- `main ⊆ develop` verified before opening.

## Checklist

- [x] Updated `README.md` / `CLAUDE.md` where setup or behaviour changed
- [x] `main ⊆ develop` verified before opening
- [x] Merge with `--merge`, **not** `--squash`; do **not** delete `develop`

> After all repos land, cut the shared release tag. The last one was `202609-s1-rc1`.
