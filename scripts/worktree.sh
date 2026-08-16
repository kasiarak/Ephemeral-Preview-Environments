#!/usr/bin/env bash
set -euo pipefail

ref="${1:?ref is required}"
name="${2:?name is required}"

worktree="$PWD/.worktrees/$name"

git fetch --quiet origin "$ref" 2>/dev/null || true

target="origin/$ref"
git rev-parse --verify --quiet "$target" >/dev/null || target="$ref"

if [[ -d "$worktree" ]]; then
  git -C "$worktree" checkout --quiet --detach "$target"
else
  git worktree add --quiet --detach "$worktree" "$target"
fi

echo "$worktree"
