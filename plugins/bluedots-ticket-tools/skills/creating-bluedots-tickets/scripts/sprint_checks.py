"""Sprint review checks for org Project #1, following references/sprint-board-guidelines.md.
usage: python3 sprint_checks.py board.json <sprint> [--active]
  board.json from fetch_board.py; --active leaves out "still open" while the sprint is running.
Scope: items with Sprint == <sprint>, plus Stories that have a child in it.
Leaves out tickets closed as not planned or duplicate, and the bluedots-program Epics."""
import json, sys
from collections import defaultdict
items, S = json.load(open(sys.argv[1])), sys.argv[2]
by = {}
for i in items:
    c = i["content"]
    if not c or not c.get("number"): continue
    v = {x["field"]["name"]: x.get("name", x.get("number", x.get("text"))) for x in i["fieldValues"]["nodes"] if x and x.get("field")}
    by[c["id"]] = (c, v)
skip = lambda c: (c["state"] == "CLOSED" and c.get("stateReason") in ("NOT_PLANNED", "DUPLICATE")) or \
                 (c["repository"]["name"] == "bluedots-program" and (c.get("issueType") or {}).get("name") == "Epic")
short = {"bluedots-infra-deployments": "infra"}
k = lambda c: f'{short.get(c["repository"]["name"], c["repository"]["name"])}#{c["number"]}'
typ = lambda c: (c.get("issueType") or {}).get("name")
kids = defaultdict(list)
for c, v in by.values():
    if c.get("parent") and not skip(c): kids[c["parent"]["id"]].append((c, v))
scope = {cid for cid, (c, v) in by.items() if not skip(c) and (v.get("Sprint") == S or
         (typ(c) == "Story" and any(cv.get("Sprint") == S for _, cv in kids[cid])))}
TIER = [(.5, 1), (1, 2), (2, 3), (3, 5), (5, 8), (1e9, 13)]
SCALE = [1, 2, 3, 5, 8, 13]  # <=0.5d 1, 1d 2, 1.5-2d 3, 3d 5, 4-5d 8, 6-10d 13
DAY_EDGES = [0.5, 1, 2, 3, 5]  # upper bound in days for 1, 2, 3, 5, 8; above = 13
def tier_of_days(d): return next((i for i, e in enumerate(DAY_EDGES) if d <= e), 5)
def tier_of_sp(sp): return min(range(6), key=lambda i: abs(SCALE[i] - sp))
rows = defaultdict(list)
for cid in scope:
    c, v = by[cid]; t = typ(c); g = []; key = k(c)
    sp, est = v.get("Story Points"), v.get("Estimate (d)")
    p = c.get("parent"); pt = (p or {}).get("issueType", {}) and p["issueType"]["name"] if p else None
    # hierarchy
    if t == "Story":
        if not p: g.append("no parent (needs Epic)")
        elif pt != "Epic": g.append(f"parent is {pt or 'untyped'}, not Epic")
    elif t in ("Task", "Bug"):
        if not p: g.append("no parent (needs Story)")
        elif pt != "Story": g.append(f"parent is {pt or 'untyped'}, not Story")
    elif t != "Epic": g.append("no issue type")  # in-repo Epics are fine
    # sizing
    days = sum(cv.get("Estimate (d)") or 0 for _, cv in kids[cid])
    if t == "Story":
        if sp is None: g.append("no SP" + (f" (tasks {days:g}d → {next(p for d,p in TIER if days<=d)})" if days else ""))
        elif sp not in SCALE: g.append(f"SP {sp:g} off the 1/2/3/5/8/13 scale")
        if est is not None: g.append(f"has estimate {est:g}d")
        # SP is a range, not exact: flag only when child days land 2+ tiers away
        if sp is not None and days and abs(tier_of_days(days) - tier_of_sp(sp)) >= 2:
            g.append(f"child estimates {days:g}d far from {sp:g} SP")
    if t in ("Task", "Bug"):
        if est is None: g.append("no estimate")
        if sp is not None: g.append(f"has SP {sp:g}")
    if t == "Epic" and (sp is not None or est is not None): g.append("Epic has SP/estimate")
    # other fields
    na = len(c["assignees"]["nodes"])
    if not na: g.append("no assignee")
    elif na > 1 and t in ("Task", "Bug"): g.append(f"{na} assignees (one per Task; split it)")
    elif na > 1 and t == "Story" and not any((cv.get("Estimate (d)") or 0) > 0 for _, cv in kids[cid]):
        g.append(f"{na} assignees, no estimated Tasks (add a Task per person)")
    for f in ("Epic", "Category", "Work Type", "Sprint Entry"):
        if v.get(f) is None and not (f == "Sprint Entry" and v.get("Sprint") != S): g.append(f"no {f}")
    if t == "Bug" and v.get("Work Type") not in (None, "Bug"): g.append(f"Bug with Work Type {v.get('Work Type')}")
    if v.get("Sprint") != S: g.append(f"sprint {v.get('Sprint') or '—'} (child in {S})" if t == "Story" else f"sprint {v.get('Sprint') or '—'}")
    if c["state"] == "OPEN" and "--active" not in sys.argv: g.append(f"still open (status {v.get('Status')})" + (f", Carry Count {v['Carry Count']:g}" if v.get("Carry Count") else ""))
    elif c["state"] == "CLOSED" and v.get("Status") != "Done": g.append(f"closed but status {v.get('Status')}")
    if v.get("Sprint Entry") == "Carried-forward" and not v.get("Slip Reason") and c["state"] == "OPEN": g.append("carried-forward, no Slip Reason")
    if p and c["state"] == "OPEN" and p["id"] in by and by[p["id"]][0]["state"] == "CLOSED": g.append("open under closed parent")
    if t == "Task" and kids[cid]: g.append(f"Task has {len(kids[cid])} children (should be a Story)")
    if t == "Story" and c["state"] == "CLOSED" and any(cc["state"] == "OPEN" for cc, _ in kids[cid]): g.append("closed with open children")
    if t == "Story" and c["state"] == "OPEN" and kids[cid] and all(cc["state"] == "CLOSED" for cc, _ in kids[cid]): g.append("open but all children closed")
    pk = k(p) if p else "—"
    rows[c["repository"]["name"]].append((key, c["title"][:48], t or "—", pk, f"{est:g}" if est is not None else "—",
                                          f"{sp:g}" if sp is not None else "—", "; ".join(g)))
tot = sum(len(r) for r in rows.values()); bad = sum(1 for r in rows.values() for x in r if x[-1])
print(f"{S}: {tot} issues in scope, {bad} with gaps\n")
for repo in sorted(rows):
    r = sorted((x for x in rows[repo] if x[-1]), key=lambda x: int(x[0].split("#")[1]))
    if not r: continue
    print(f"### {repo}\n| Issue | Type | Parent | Est (d) | SP | Gap |\n|---|---|---|---|---|---|")
    for x in r: print(f"| {x[0]} {x[1]} | {x[2]} | {x[3]} | {x[4]} | {x[5]} | {x[6]} |")
    print()
ok = [x[0] for r in rows.values() for x in r if not x[-1]]
print("no gaps:", len(ok))
