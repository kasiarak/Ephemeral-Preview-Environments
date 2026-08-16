#!/usr/bin/env bash
set -euo pipefail

: "${PR:?PR is required}"
COMMIT="${COMMIT:-unknown}"
REF="${REF:-}"
PREVIEW_DIR="${PREVIEW_DIR:-terraform/envs/preview}"
PUBLIC_PORT="${PUBLIC_PORT:-4566}"

workspace="pr-$PR"
worktree="$PWD/.worktrees/$workspace"

tf() {
  terraform -chdir="$PREVIEW_DIR" "$@"
}

tf init -input=false >/dev/null
tf workspace select -or-create "$workspace" >/dev/null

# Where the code comes from, in order of precedence: an explicit REF, the ref
# this environment was last built from, or the branch the pull request points
# at on GitHub. Falling through all three means building from the working tree,
# which is what happens for environments with no pull request behind them.
if [[ -z "$REF" ]]; then
  REF="$(tf output -raw git_ref 2>/dev/null || true)"
fi

if [[ -z "$REF" ]]; then
  REF="$(gh pr view "$PR" --json headRefName -q .headRefName 2>/dev/null || true)"
fi

app_root=""

if [[ -n "$REF" ]]; then
  git fetch --quiet origin "$REF" 2>/dev/null || true

  # Detached worktrees keep the environment independent of the branch checked
  # out in the main working tree, so several environments can be built from
  # different refs at the same time.
  target="origin/$REF"
  git rev-parse --verify --quiet "$target" >/dev/null || target="$REF"

  if [[ -d "$worktree" ]]; then
    git -C "$worktree" checkout --quiet --detach "$target"
  else
    git worktree add --quiet --detach "$worktree" "$target"
  fi

  app_root="$worktree"

  if [[ "$COMMIT" == "unknown" ]]; then
    COMMIT="$(git -C "$worktree" rev-parse HEAD)"
  fi

  printf 'Building %s from %s (%s)\n' "$workspace" "$REF" "${COMMIT:0:7}"
else
  printf 'Building %s from the working tree\n' "$workspace"
fi

tf apply -auto-approve -input=false \
  -var "pr_number=$PR" \
  -var "commit_sha=$COMMIT" \
  -var "public_port=$PUBLIC_PORT" \
  -var "git_ref=$REF" \
  -var "app_root=$app_root"
