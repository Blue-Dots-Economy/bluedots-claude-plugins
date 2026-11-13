"""Save every item on org Project #1 (issues with board fields) to a JSON file.
usage: python3 fetch_board.py board.json   (needs the GitHub CLI, signed in)"""
import json, subprocess, sys, time

Q = """query($after:String){organization(login:"Blue-Dots-Economy"){projectV2(number:1){
 items(first:25,after:$after){pageInfo{hasNextPage endCursor} nodes{id
  content{... on Issue{id number title url state stateReason createdAt closedAt author{login}
   assignees(first:5){nodes{login}} issueType{name} repository{name}
   labels(first:30){nodes{name}}
   parent{id number title repository{name} issueType{name}}
   subIssues{totalCount}}}
  fieldValues(first:40){nodes{
   ... on ProjectV2ItemFieldSingleSelectValue{name field{... on ProjectV2FieldCommon{name}}}
   ... on ProjectV2ItemFieldNumberValue{number field{... on ProjectV2FieldCommon{name}}}
   ... on ProjectV2ItemFieldTextValue{text field{... on ProjectV2FieldCommon{name}}}}}}}}}}"""

items, after = [], None
while True:
    args = ["gh", "api", "graphql", "-f", f"query={Q}"] + (["-f", f"after={after}"] if after else [])
    for attempt in range(4):
        r = subprocess.run(args, capture_output=True, text=True)
        if r.returncode == 0:
            break
        time.sleep(5 * (attempt + 1))
    else:
        sys.exit(r.stderr)
    page = json.loads(r.stdout)["data"]["organization"]["projectV2"]["items"]
    items += page["nodes"]
    if not page["pageInfo"]["hasNextPage"]:
        break
    after = page["pageInfo"]["endCursor"]
json.dump(items, open(sys.argv[1], "w"))
print(f"{len(items)} items", file=sys.stderr)
