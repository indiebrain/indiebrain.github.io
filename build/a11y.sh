#!/usr/bin/env bash
#
# Audit the built site against WCAG 2.2 Level AAA with pa11y.
#
# Serves the generated site directory, runs pa11y against every URL in
# Hugo's sitemap (rewriting the production base URL to localhost), then
# stops the server. Exits non-zero if any page has accessibility errors,
# so it can gate `make build` / `make deploy`.
#
# Runs inside the build container, which provides pa11y-ci, http-server,
# and a headless Chrome. Configuration lives in .pa11yci.json (shared with
# the GitHub Actions accessibility workflow).
#
# Overridable via the environment:
#   A11Y_PORT       port for the local server        (default 8099)
#   A11Y_BASE_URL   base URL to rewrite in the sitemap (default the
#                   production URL baked into the sitemap)
set -euo pipefail

root="${1:-public}"
port="${A11Y_PORT:-8099}"
base="${A11Y_BASE_URL:-https://aaronkuehler.com}"
origin="http://127.0.0.1:${port}"

if [ ! -f "${root}/sitemap.xml" ]; then
  echo "a11y: ${root}/sitemap.xml not found -- build the site first (make build)." >&2
  exit 1
fi

http-server "${root}" -a 127.0.0.1 -p "${port}" --silent &
server=$!
trap 'kill "${server}" 2>/dev/null || true' EXIT

# Wait for the server to start answering.
for _ in $(seq 1 30); do
  curl -sf "${origin}/index.html" >/dev/null 2>&1 && break
  sleep 1
done

pa11y-ci --config .pa11yci.json \
  --sitemap "${origin}/sitemap.xml" \
  --sitemap-find "${base}" \
  --sitemap-replace "${origin}"
