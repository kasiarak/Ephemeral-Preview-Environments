#!/usr/bin/env bash
set -euo pipefail

: "${API_URL:?API_URL is required}"
: "${SITE_URL:?SITE_URL is required}"
: "${PR_NUMBER:?PR_NUMBER is required}"
COMMIT_SHA="${COMMIT_SHA:-}"

failures=0

check() {
  local label=$1 expected=$2 actual=$3

  if [[ "$expected" == "$actual" ]]; then
    printf '  ok    %s\n' "$label"
  else
    printf '  FAIL  %s (expected %s, got %s)\n' "$label" "$expected" "$actual"
    failures=$((failures + 1))
  fi
}

status_of() {
  curl -s -o /dev/null -m 10 -w '%{http_code}' "$1"
}

body_of() {
  curl -s -m 10 "$1"
}

printf 'Smoke testing pr-%s\n' "$PR_NUMBER"

check "GET /health returns 200" "200" "$(status_of "$API_URL/health")"
check "GET /health reports ok" "ok" "$(body_of "$API_URL/health" | jq -r '.status')"
check "GET /info returns 200" "200" "$(status_of "$API_URL/info")"
check "GET /info reports the environment" "pr-$PR_NUMBER" "$(body_of "$API_URL/info" | jq -r '.env')"
check "GET /info reports the pull request" "$PR_NUMBER" "$(body_of "$API_URL/info" | jq -r '.pr')"

if [[ -n "$COMMIT_SHA" && "$COMMIT_SHA" != "unknown" ]]; then
  check "GET /info reports the commit" "$COMMIT_SHA" "$(body_of "$API_URL/info" | jq -r '.commit')"
fi

check "unknown path returns 404" "404" "$(status_of "$API_URL/nope")"
check "site returns 200" "200" "$(status_of "$SITE_URL")"

if body_of "$SITE_URL" | grep -q "pr-$PR_NUMBER"; then
  printf '  ok    site page names the environment\n'
else
  printf '  FAIL  site page does not mention pr-%s\n' "$PR_NUMBER"
  failures=$((failures + 1))
fi

if ((failures > 0)); then
  printf '%d check(s) failed\n' "$failures" >&2
  exit 1
fi

printf 'All checks passed\n'
