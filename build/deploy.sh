#!/usr/bin/env bash
#
# Break-glass publish: force-push the built site (public/) to the
# gh-pages branch, for serving via Pages "Deploy from a branch" if GitHub
# Actions is ever unavailable. Normal deploys happen automatically from
# `master` via Actions — this is only a fallback.
#
# Run via `make deploy` (which clean-builds first). Set DEPLOY_BRANCH to
# override the target branch.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"
[ -d public ] || { echo "deploy: public/ not found — build first"; exit 1; }

branch="${DEPLOY_BRANCH:-gh-pages}"
url="$(git remote get-url origin)"
ref="$(git rev-parse --short HEAD)"

tmp="$(mktemp -d)"
cleanup() { rm -rf "$tmp"; }
trap cleanup EXIT

# Fresh single-commit repo of just the built site, force-pushed to the
# publish branch (its history is disposable generated output).
cp -R public/. "$tmp/"
cd "$tmp"
git init -q -b "$branch"
git add -A
git -c user.email=deploy@localhost -c user.name=deploy commit -q -m "Publish site ($ref)"
git push -q -f "$url" "$branch"
echo "deploy: force-pushed build to $branch"
