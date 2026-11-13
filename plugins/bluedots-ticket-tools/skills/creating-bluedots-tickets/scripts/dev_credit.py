"""Per-person Story Points for a sprint on org Project #1, counted two ways.
usage: python3 dev_credit.py <sprint>     (reads board.json from fetch_board.py)

A  Story assignee: each Story's points go to its assignees, split evenly.
B  Task share: each Story's points are split by its Tasks' and Bugs' estimates, credited to
   their assignees (see "Assignees and credit" in references/sprint-board-guidelines.md).
   A Story with no estimated Tasks falls back to A. A Task with no assignee counts for the Story's.
Task days: estimates of Tasks and Bugs whose Sprint is <sprint>, per assignee.
Leaves out tickets closed as not planned or duplicate. Stories counted: Sprint == <sprint>."""
import json, sys


BOARD = "board.json"  # written by fetch_board.py in the current folder

EST = "Estimate (d)"
from collections import defaultdict

with open(BOARD) as fh:
    items = json.load(fh)
S = sys.argv[1]
fv = lambda it: {x["field"]["name"]: x.get("name", x.get("number", x.get("text")))
                 for x in it["fieldValues"]["nodes"] if x and x.get("field")}
skip = lambda c: c["state"] == "CLOSED" and c.get("stateReason") in ("NOT_PLANNED", "DUPLICATE")
typ = lambda c: (c.get("issueType") or {}).get("name")
who = lambda c: [a["login"] for a in c["assignees"]["nodes"]]
kids, stories, tasks = defaultdict(list), [], []
for it in items:
    c = it["content"]
    if not c or not c.get("number") or skip(c): continue
    f = fv(it)
    if typ(c) in ("Task", "Bug"):
        if c.get("parent"): kids[c["parent"]["id"]].append((c, f))
        if f.get("Sprint") == S: tasks.append((c, f))
    elif typ(c) == "Story" and f.get("Sprint") == S:
        stories.append((c, f))

A, B, days, untasked = defaultdict(float), defaultdict(float), defaultdict(float), []
for c, f in stories:
    sp, owners = f.get("Story Points") or 0, who(c) or ["(no assignee)"]
    for a in owners: A[a] += sp / len(owners)
    est = [(k, kf[EST]) for k, kf in kids[c["id"]] if (kf.get(EST) or 0) > 0]
    total = sum(d for _, d in est)
    if not total:
        for a in owners: B[a] += sp / len(owners)
        untasked.append(f'{c["repository"]["name"]}#{c["number"]} ({sp:g} SP, {", ".join(owners)})')
        continue
    for k, d in est:
        doers = who(k) or owners
        for a in doers: B[a] += sp * d / total / len(doers)
for c, f in tasks:
    doers = who(c) or ["(no assignee)"]
    for a in doers: days[a] += (f.get(EST) or 0) / len(doers)

print(f"{S}: {len(stories)} Stories, {sum(A.values()):g} SP\n")
print("| Person | A: Story assignee | B: Task share | Change | Task days |\n|---|---|---|---|---|")
for p in sorted(set(A) | set(B) | set(days), key=lambda p: -B.get(p, 0)):
    print(f"| {p} | {A.get(p, 0):.1f} | {B.get(p, 0):.1f} | {B.get(p, 0) - A.get(p, 0):+.1f} | {days.get(p, 0):.2f} |")
print(f"| Total | {sum(A.values()):.1f} | {sum(B.values()):.1f} | | {sum(days.values()):.2f} |")
if untasked:
    print(f"\nStories with no estimated Tasks (credited to the assignee both ways): {len(untasked)}")
    for u in untasked: print(f"- {u}")
