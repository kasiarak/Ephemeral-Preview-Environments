#!/usr/bin/env bash
set -euo pipefail

: "${ENV_NAME:?ENV_NAME is required}"
: "${ENV_DIR:?ENV_DIR is required}"
REF="${REF:-}"
COMMAND="${COMMAND:-apply}"
AUTO_APPROVE="${AUTO_APPROVE:-0}"
PUBLIC_PORT="${PUBLIC_PORT:-4566}"

tf() {
  terraform -chdir="$ENV_DIR" "$@"
}

tf init -input=false >/dev/null

if [[ -z "$REF" ]]; then
  stored="$(tf output -raw git_ref 2>/dev/null || true)"
  if [[ "$stored" =~ ^[A-Za-z0-9._/-]+$ ]]; then
    REF="$stored"
  fi
fi

if [[ -z "$REF" ]]; then
  echo "REF is required for the first deployment of $ENV_NAME, for example REF=v1.0.0" >&2
  exit 1
fi

worktree="$(./scripts/worktree.sh "$REF" "$ENV_NAME")"
commit="$(git -C "$worktree" rev-parse HEAD)"

printf 'Deploying %s from %s (%s)\n' "$ENV_NAME" "$REF" "${commit:0:7}"

args=("$COMMAND" -input=false)

if [[ "$COMMAND" == "apply" && "$AUTO_APPROVE" == "1" ]]; then
  args+=(-auto-approve)
fi

args+=(
  -var "commit_sha=$commit"
  -var "public_port=$PUBLIC_PORT"
  -var "git_ref=$REF"
  -var "app_root=$worktree"
)

tf "${args[@]}"
