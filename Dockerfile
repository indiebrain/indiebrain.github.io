# One build toolchain for local development and CI: Emacs + ox-hugo
# (Org -> Markdown), a small TeX Live (resume PDF), Hugo extended, and a
# headless Google Chrome + pa11y for the WCAG AAA accessibility audit.
#
# Build:  docker build -t site-builder .
# Use:    docker run --rm -v "$PWD":/site -w /site site-builder make build
#
# The image is pinned to linux/amd64: Google Chrome (used by the audit)
# ships no Linux arm64 build. CI runners are amd64, so this is native
# there; on Apple Silicon it runs under emulation, which is fine for the
# occasional container build.
FROM --platform=linux/amd64 ubuntu:24.04

ARG HUGO_VERSION=0.163.3

ENV DEBIAN_FRONTEND=noninteractive \
    SITE_ELPA=/opt/elpa

RUN apt-get update && apt-get install -y --no-install-recommends \
      emacs-nox \
      texlive-latex-recommended texlive-fonts-recommended \
      make git rsync curl ca-certificates gnupg \
    && rm -rf /var/lib/apt/lists/*

# Hugo extended (amd64, matching the pinned image platform).
RUN curl -fsSL "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-amd64.tar.gz" \
      | tar -xz -C /usr/local/bin hugo \
    && hugo version

# Pre-install ox-hugo into a fixed package dir so builds need no network.
# build/export.el reads SITE_ELPA and skips the MELPA bootstrap when it
# finds ox-hugo already here.
RUN emacs --batch -Q \
      --eval "(require 'package)" \
      --eval "(setq package-user-dir (getenv \"SITE_ELPA\"))" \
      --eval "(setq package-archives '((\"gnu\" . \"https://elpa.gnu.org/packages/\") (\"melpa\" . \"https://melpa.org/packages/\")))" \
      --eval "(package-initialize)" \
      --eval "(package-refresh-contents)" \
      --eval "(package-install 'ox-hugo)" \
    && chmod -R a+rX "$SITE_ELPA"

# Node.js and a headless Google Chrome for the accessibility audit, plus
# pa11y-ci and a small static file server. Chrome is installed from
# Google's apt repository so its runtime libraries are resolved for us.
# pa11y is pointed at this system Chrome and Puppeteer's own browser
# download is skipped, so `.pa11yci.json` stays shared with CI (which uses
# a Puppeteer-managed Chrome instead).
ENV PUPPETEER_SKIP_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome-stable

RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && curl -fsSL https://dl.google.com/linux/linux_signing_key.pub \
         | gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" \
         > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends google-chrome-stable \
    && npm install -g pa11y-ci http-server \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /site
