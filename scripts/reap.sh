#!/usr/bin/env bash
set -euo pipefail

PREVIEW_DIR="${PREVIEW_DIR:-terraform/envs/preview}"
TTL_HOURS="${TTL_HOURS:-24}"
FORCE="${FORCE:-0}"

workspaces="$(terraform -chdir="$PREVIEW_DIR" workspace list | sed 's/^[* ] *//' | grep '^pr-' || true)"

if [[ -z "$workspaces" ]]; then
  echo "no preview environments"
  exit 0
fi

now="$(date +%s)"
stale=""

for workspace in $workspaces; do
  pr="${workspace#pr-}"
  state="$(gh pr view "$pr" --json state -q .state 2>/dev/null || true)"

  if [[ "$state" == "OPEN" ]]; then
    printf '  keep     %s  pull request open\n' "$workspace"
    continue
  fi

  if [[ "$state" == "CLOSED" || "$state" == "MERGED" ]]; then
    printf '  destroy  %s  pull request %s\n' "$workspace" "$(echo "$state" | tr '[:upper:]' '[:lower:]')"
    stale="$stale $pr"
    continue
  fi

  last_modified="$(aws lambda get-function-configuration \
    --function-name "$workspace-api" --query LastModified --output text 2>/dev/null || true)"

  if [[ -z "$last_modified" || "$last_modified" == "None" ]]; then
    printf '  destroy  %s  no pull request, no function deployed\n' "$workspace"
    stale="$stale $pr"
    continue
  fi

  updated="$(python3 -c 'import sys, datetime; print(int(datetime.datetime.fromisoformat(sys.argv[1].replace("+0000", "+00:00")).timestamp()))' "$last_modified")"
  age=$(((now - updated) / 3600))

  if ((age >= TTL_HOURS)); then
    printf '  destroy  %s  no pull request, idle %sh\n' "$workspace" "$age"
    stale="$stale $pr"
  else
    printf '  keep     %s  no pull request, idle %sh of %sh\n' "$workspace" "$age" "$TTL_HOURS"
  fi
done

count="$(echo "$stale" | wc -w | tr -d ' ')"

if [[ "$count" == "0" ]]; then
  echo "nothing to reap"
  exit 0
fi

if [[ "$FORCE" != "1" ]]; then
  printf '\n%s environment(s) would be destroyed, run "make reap-force" to do it\n' "$count"
  exit 0
fi

for pr in $stale; do
  make env-down PR="$pr"
done
