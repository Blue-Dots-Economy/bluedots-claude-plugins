#!/usr/bin/env bash
# File a Blue Dots ticket (Story, Task or Bug) with every binding the sprint-board
# guidelines require: epic label, issue type, one parent, and the Project #1 fields.
#
# Usage:
#   file_ticket.sh --repo <repo> --type <Story|Task|Bug> --epic <CODE> \
#                  --title "<title>" --body-file <path> --work-type <Planned|Interrupt|Bug|Spike|Chore> \
#                  [--parent <issue #> [--parent-repo <repo>]] \
#                  [--story-points 1|2|3|5|8|13]   (Story only) \
#                  [--estimate DAYS]               (Task/Bug only) \
#                  [--sprint "<option>" [--sprint-entry New|Carried-forward]] \
#                  [--assignee LOGIN] [--labels "a,b"] [--priority p0|p1|p2] [--dry-run]
#
# Parents: a Task or Bug needs --parent pointing at a Story (any repo in the org).
# A Story attaches to the program epic, or to --parent if given. One parent only.
# Epics are not filed with this script; see SKILL.md.
set -euo pipefail

ORG="Blue-Dots-Economy"
PROGRAM_REPO="bluedots-program"
PROJECT_NUM=1

die() { echo "ERROR: $*" >&2; exit 1; }
warn() { echo "WARN:  $*" >&2; }

REPO=""; TITLE=""; BODY_FILE=""; TYPE=""; EPIC=""; LABELS=""; PRIORITY=""; DRY=0
PARENT=""; PARENT_REPO=""; ASSIGNEE=""; ESTIMATE=""; POINTS=""; SPRINT=""; SPRINT_ENTRY=""; WORK_TYPE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)         REPO="$2"; shift 2 ;;
    --title)        TITLE="$2"; shift 2 ;;
    --body-file)    BODY_FILE="$2"; shift 2 ;;
    --type)         TYPE="$2"; shift 2 ;;
    --epic)         EPIC="$2"; shift 2 ;;
    --labels)       LABELS="$2"; shift 2 ;;
    --priority)     PRIORITY="$2"; shift 2 ;;
    --parent)       PARENT="$2"; shift 2 ;;
    --parent-repo)  PARENT_REPO="$2"; shift 2 ;;
    --assignee)     ASSIGNEE="$2"; shift 2 ;;
    --estimate)     ESTIMATE="$2"; shift 2 ;;
    --story-points) POINTS="$2"; shift 2 ;;
    --sprint)       SPRINT="$2"; shift 2 ;;
    --sprint-entry) SPRINT_ENTRY="$2"; shift 2 ;;
    --work-type)    WORK_TYPE="$2"; shift 2 ;;
    --dry-run)      DRY=1; shift ;;
    *) die "unknown flag: $1" ;;
  esac
done

[[ -n "$REPO"  ]] || die "--repo is required"
[[ -n "$TITLE" ]] || die "--title is required"
[[ -n "$EPIC"  ]] || die "--epic is required (e.g. FN-ONBOARD)"
[[ -n "$BODY_FILE" && -f "$BODY_FILE" ]] || die "--body-file must point at an existing file"
case "$TYPE" in
  Story|Task|Bug) ;;
  Epic|Feature) die "--type $TYPE is not filed with this script: tickets are Story, Task or Bug; new epics need the program lead (see SKILL.md)" ;;
  *) die "--type must be Story, Task or Bug" ;;
esac
case "$WORK_TYPE" in
  Planned|Interrupt|Bug|Spike|Chore) ;;
  "") die "--work-type is required (first match: Bug, Spike, Planned, Chore, Interrupt)" ;;
  *) die "--work-type must be Planned, Interrupt, Bug, Spike or Chore" ;;
esac
[[ "$TYPE" != "Bug" || "$WORK_TYPE" == "Bug" ]] || die "a Bug ticket has Work Type Bug (it fixes a defect)"
[[ -z "$PRIORITY" ]] || case "$PRIORITY" in p0|p1|p2) ;; *) die "--priority must be p0, p1 or p2" ;; esac

# Sizing: Story Points on Stories only, Estimate (d) on Tasks and Bugs only.
if [[ "$TYPE" == "Story" ]]; then
  [[ -z "$ESTIMATE" ]] || die "Stories carry Story Points, not --estimate"
  [[ -z "$POINTS" ]] || case "$POINTS" in 1|2|3|5|8|13) ;; *) die "--story-points must be 1, 2, 3, 5, 8 or 13" ;; esac
  [[ -n "$POINTS" ]] || warn "no --story-points (fine only for an OP support Story, pointed at sprint close)"
else
  [[ -z "$POINTS" ]] || die "Tasks and Bugs carry --estimate (dev days), never Story Points"
  [[ -n "$ESTIMATE" ]] || warn "no --estimate: the board's refinement view will flag this ticket"
fi

# Parent: a Task or Bug must sit under a Story.
PARENT_REPO="${PARENT_REPO:-$REPO}"
if [[ "$TYPE" != "Story" ]]; then
  [[ -n "$PARENT" ]] || die "a $TYPE needs --parent <Story #> (pick it from Project #1 view 26)"
fi
if [[ -n "$PARENT" ]]; then
  PARENT_TYPE=$(gh api graphql -f query="{repository(owner:\"$ORG\",name:\"$PARENT_REPO\"){issue(number:$PARENT){issueType{name} state}}}" \
    -q '.data.repository.issue.issueType.name // "none"') || die "parent $PARENT_REPO#$PARENT not found"
  if [[ "$TYPE" != "Story" && "$PARENT_TYPE" != "Story" ]]; then
    die "parent $PARENT_REPO#$PARENT is a '$PARENT_TYPE', not a Story"
  fi
fi

# Sprint and Sprint Entry go together; empty Sprint means backlog.
if [[ -n "$SPRINT" ]]; then
  SPRINT_ENTRY="${SPRINT_ENTRY:-New}"
  case "$SPRINT_ENTRY" in New|Carried-forward) ;; *) die "--sprint-entry must be New or Carried-forward" ;; esac
else
  [[ -z "$SPRINT_ENTRY" ]] || die "--sprint-entry needs --sprint (backlog tickets have neither)"
fi

# Category is mechanical from the epic prefix.
case "$EPIC" in
  FN-*) CATEGORY="Functional" ;;
  TE-*) CATEGORY="Technical" ;;
  OP-*) CATEGORY="Operational" ;;
  DE-*) CATEGORY="Design" ;;
  *) die "epic code '$EPIC' has no known prefix (FN-/TE-/OP-/DE-)" ;;
esac

# Resolve the epic's issue number in the program repo: by title "[CODE] ...",
# else by an `epic:<CODE>` label on the epic (some epics carry no code in the title).
EPIC_NUM=$(gh issue list -R "$ORG/$PROGRAM_REPO" --state open --limit 100 \
  --json number,title -q ".[] | select(.title | startswith(\"[$EPIC]\")) | .number")
if [[ -z "$EPIC_NUM" ]]; then
  EPIC_NUM=$(gh issue list -R "$ORG/$PROGRAM_REPO" --state open --limit 100 \
    --label "epic:$EPIC" --json number -q '.[].number')
fi
[[ -n "$EPIC_NUM" ]] || die "no open epic titled '[$EPIC] ...' or labelled 'epic:$EPIC' in $PROGRAM_REPO"
[[ $(wc -l <<<"$EPIC_NUM") -eq 1 ]] || die "epic code '$EPIC' matched multiple issues: $EPIC_NUM"

# Preflight: the epic label must exist in the target repo, or issue create fails.
# Collected into a variable rather than piped straight into `grep -q`: -q exits on
# the first match, which SIGPIPEs `gh`, and under `pipefail` that intermittently
# reports a label that exists as missing.
REPO_LABELS=$(gh label list -R "$ORG/$REPO" --limit 200 --json name -q '.[].name')
grep -qx "epic:$EPIC" <<<"$REPO_LABELS" \
  || die "label 'epic:$EPIC' does not exist in $REPO — create it first (see SKILL.md)"

if [[ -n "$ASSIGNEE" ]]; then
  gh api "repos/$ORG/$REPO/assignees/$ASSIGNEE" --silent 2>/dev/null \
    || die "'$ASSIGNEE' cannot be assigned in $REPO (not a collaborator)"
else
  warn "no --assignee (the guidelines expect one at creation)"
fi

# Board field metadata, also used to validate option values before anything is created.
FIELDS_JSON=$(gh api graphql -f query="{organization(login:\"$ORG\"){projectV2(number:$PROJECT_NUM){id fields(first:40){nodes{... on ProjectV2SingleSelectField{id name options{id name}} ... on ProjectV2Field{id name}}}}}}")
PROJECT_ID=$(jq -r '.data.organization.projectV2.id' <<<"$FIELDS_JSON")
option_exists() {
  jq -e --arg f "$1" --arg o "$2" \
    '.data.organization.projectV2.fields.nodes[] | select(.name==$f) | .options[] | select(.name==$o)' \
    <<<"$FIELDS_JSON" >/dev/null
}
option_exists "Epic" "$EPIC" || die "board field 'Epic' has no option '$EPIC' — add it first (scripts/add_epic_option.sh)"
[[ -z "$SPRINT" ]] || option_exists "Sprint" "$SPRINT" || die "board field 'Sprint' has no option '$SPRINT'"

ALL_LABELS="epic:$EPIC${LABELS:+,$LABELS}"

echo "repo:      $ORG/$REPO"
echo "title:     $TITLE"
echo "type:      $TYPE"
echo "labels:    $ALL_LABELS"
if [[ -n "$PARENT" ]]; then
  echo "parent:    $PARENT_REPO#$PARENT (${PARENT_TYPE})"
else
  echo "parent:    $PROGRAM_REPO#$EPIC_NUM [$EPIC]"
fi
echo "assignee:  ${ASSIGNEE:-none}"
echo "board:     Project #$PROJECT_NUM · Epic=$EPIC · Category=$CATEGORY · Work Type=$WORK_TYPE${SPRINT:+ · Sprint=$SPRINT · Sprint Entry=$SPRINT_ENTRY}${POINTS:+ · Story Points=$POINTS}${ESTIMATE:+ · Estimate=${ESTIMATE}d}${PRIORITY:+ · Priority=$PRIORITY}"
echo "--- body ---"; cat "$BODY_FILE"; echo "--- end body ---"

if [[ $DRY -eq 1 ]]; then echo "[dry-run] nothing created"; exit 0; fi

URL=$(gh issue create -R "$ORG/$REPO" \
        --title "$TITLE" --body-file "$BODY_FILE" \
        --type "$TYPE" --label "$ALL_LABELS" ${ASSIGNEE:+--assignee "$ASSIGNEE"})
echo "created: $URL"
NUM="${URL##*/}"

# --- exactly one parent ---
CHILD_ID=$(gh api "repos/$ORG/$REPO/issues/$NUM" -q .id)
if [[ -n "$PARENT" ]]; then
  gh api "repos/$ORG/$PARENT_REPO/issues/$PARENT/sub_issues" -X POST -F sub_issue_id="$CHILD_ID" >/dev/null
  echo "linked:  sub-issue of $PARENT_REPO#$PARENT"
else
  gh api "repos/$ORG/$PROGRAM_REPO/issues/$EPIC_NUM/sub_issues" -X POST -F sub_issue_id="$CHILD_ID" >/dev/null
  echo "linked:  sub-issue of $PROGRAM_REPO#$EPIC_NUM [$EPIC]"
fi

# --- board item + fields ---
# The board's auto-add workflow may have added the issue already; item-add then fails,
# so fall back to the existing item.
if ITEM_ID=$(gh project item-add "$PROJECT_NUM" --owner "$ORG" --url "$URL" --format json -q .id 2>/dev/null); then
  echo "board:   added ($ITEM_ID)"
else
  ITEM_ID=$(gh api graphql -f query="{repository(owner:\"$ORG\",name:\"$REPO\"){issue(number:$NUM){projectItems(first:10){nodes{id project{number}}}}}}" \
    -q ".data.repository.issue.projectItems.nodes[] | select(.project.number==$PROJECT_NUM) | .id")
  [[ -n "$ITEM_ID" ]] || die "could not add $URL to project #$PROJECT_NUM or find its existing item"
  echo "board:   already on board ($ITEM_ID)"
fi

set_field() {
  local field="$1" option="$2"
  local fid oid
  fid=$(jq -r --arg f "$field" '.data.organization.projectV2.fields.nodes[] | select(.name==$f) | .id' <<<"$FIELDS_JSON")
  oid=$(jq -r --arg f "$field" --arg o "$option" \
        '.data.organization.projectV2.fields.nodes[] | select(.name==$f) | .options[] | select(.name==$o) | .id' <<<"$FIELDS_JSON")
  [[ -n "$fid" && "$fid" != "null" ]] || die "board field '$field' not found"
  [[ -n "$oid" && "$oid" != "null" ]] || die "board field '$field' has no option '$option'"
  gh project item-edit --id "$ITEM_ID" --project-id "$PROJECT_ID" --field-id "$fid" --single-select-option-id "$oid" >/dev/null
  echo "field:   $field = $option"
}

set_number_field() {
  local field="$1" value="$2" fid
  fid=$(jq -r --arg f "$field" '.data.organization.projectV2.fields.nodes[] | select(.name==$f) | .id' <<<"$FIELDS_JSON")
  [[ -n "$fid" && "$fid" != "null" ]] || die "board field '$field' not found"
  gh project item-edit --id "$ITEM_ID" --project-id "$PROJECT_ID" --field-id "$fid" --number "$value" >/dev/null
  echo "field:   $field = $value"
}

set_field "Epic" "$EPIC"
set_field "Category" "$CATEGORY"
set_field "Work Type" "$WORK_TYPE"
[[ -z "$SPRINT" ]] || { set_field "Sprint" "$SPRINT"; set_field "Sprint Entry" "$SPRINT_ENTRY"; }
[[ -z "$POINTS" ]] || set_number_field "Story Points" "$POINTS"
[[ -z "$ESTIMATE" ]] || set_number_field "Estimate (d)" "$ESTIMATE"
[[ -z "$PRIORITY" ]] || set_field "Priority" "$PRIORITY"

echo "done: $URL"
