#!/usr/bin/env bash
#
# Publish the built site (public/) to the `master` branch, which GitHub
# Pages serves. Run via `make deploy` (which does a clean build first).
#
# It checks out master into a throwaway worktree, replaces its contents
# with public/, commits, and pushes — so master holds only the current
# generated site and the source branch stays the source of truth.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"
[ -d public ] || { echo "deploy: public/ not found — build first"; exit 1; }

src_ref="$(git rev-parse --short HEAD)"
parent="$(mktemp -d)"
worktree="$parent/master"
cleanup() { git worktree remove --force "$worktree" 2>/dev/null || true; rm -rf "$parent"; }
trap cleanup EXIT

git fetch -q origin master
git worktree add -q --detach "$worktree" origin/master

# Replace published content with the fresh build (keep the worktree's .git).
rsync -a --delete --exclude '.git' public/ "$worktree/"

git -C "$worktree" add -A
if git -C "$worktree" diff --cached --quiet; then
  echo "deploy: no changes to publish."
  exit 0
fi
git -C "$worktree" commit -q -m "Deploy site (source $src_ref)"
git -C "$worktree" push -q origin HEAD:master
echo "deploy: published $(git -C "$worktree" rev-parse --short HEAD) to master"
