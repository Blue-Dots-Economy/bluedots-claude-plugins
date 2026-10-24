#!/usr/bin/env bash
# Append a new option to a single-select field on Project #1 WITHOUT clearing
# existing item values.
#
# updateProjectV2Field replaces the whole option list. Options resubmitted WITHOUT
# their `id` are treated as new ones, which clears that field on every item already
# using them (1000+ items on this board). This script re-sends every existing option
# with its id and appends the new one.
#
# Usage: add_epic_option.sh <field-name> <new-option-name> [COLOR] [description]
#        add_epic_option.sh Epic FN-AI-POC BLUE "PoC / demo environment setup"
#
# COLOR is a ProjectV2SingleSelectFieldOptionColor: GRAY BLUE GREEN YELLOW ORANGE RED PINK PURPLE
set -euo pipefail

ORG="Blue-Dots-Economy"
PROJECT_NUM=1

die() { echo "ERROR: $*" >&2; exit 1; }

FIELD="${1:-}"; NEW="${2:-}"; COLOR="${3:-BLUE}"; DESC="${4:-}"
[[ -n "$FIELD" && -n "$NEW" ]] || die "usage: add_epic_option.sh <field-name> <new-option-name> [COLOR] [description]"

FIELDS_JSON=$(gh api graphql -f query="{organization(login:\"$ORG\"){projectV2(number:$PROJECT_NUM){fields(first:40){nodes{... on ProjectV2SingleSelectField{id name options{id name color description}}}}}}}")

FIELD_ID=$(jq -r --arg f "$FIELD" '.data.organization.projectV2.fields.nodes[] | select(.name==$f) | .id' <<<"$FIELDS_JSON")
[[ -n "$FIELD_ID" && "$FIELD_ID" != "null" ]] || die "no single-select field named '$FIELD' on project #$PROJECT_NUM"

if jq -e --arg f "$FIELD" --arg o "$NEW" \
     '.data.organization.projectV2.fields.nodes[] | select(.name==$f) | .options[] | select(.name==$o)' <<<"$FIELDS_JSON" >/dev/null; then
  echo "option '$NEW' already exists on '$FIELD' — nothing to do"; exit 0
fi

# Existing options, each WITH its id (identity preserved), plus the new one.
OPTIONS=$(jq -c --arg f "$FIELD" --arg n "$NEW" --arg c "$COLOR" --arg d "$DESC" '
  [ .data.organization.projectV2.fields.nodes[]
    | select(.name==$f) | .options[]
    | {id, name, color, description: (.description // "")} ]
  + [ {name: $n, color: $c, description: $d} ]' <<<"$FIELDS_JSON")

COUNT=$(jq 'length' <<<"$OPTIONS")
echo "field '$FIELD': resubmitting $((COUNT-1)) existing options with ids + appending '$NEW'"

# gh's -f/-F flags can't carry a list-of-objects GraphQL variable, so post the
# request body directly.
jq -n --arg field "$FIELD_ID" --argjson options "$OPTIONS" '{
  query: "mutation($field:ID!, $options:[ProjectV2SingleSelectFieldOptionInput!]!){ updateProjectV2Field(input:{fieldId:$field, singleSelectOptions:$options}){ projectV2Field{ ... on ProjectV2SingleSelectField{ name options{name} } } } }",
  variables: { field: $field, options: $options }
}' | gh api graphql --input - \
  -q '.data.updateProjectV2Field.projectV2Field.options[].name' | tr '\n' ' '
echo
echo "done — verify the field still shows values on existing items before filing anything."
