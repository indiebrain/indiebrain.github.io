# One build toolchain for local development and CI: Emacs + ox-hugo
# (Org -> Markdown), a small TeX Live (resume PDF), and Hugo extended.
#
# Build:  docker build -t site-builder .
# Use:    docker run --rm -v "$PWD":/site -w /site site-builder make build
FROM ubuntu:26.04

# TARGETARCH is provided by BuildKit (amd64 / arm64); matches Hugo's naming.
ARG TARGETARCH
ARG HUGO_VERSION=0.163.3

ENV DEBIAN_FRONTEND=noninteractive \
    SITE_ELPA=/opt/elpa

RUN apt-get update && apt-get install -y --no-install-recommends \
      emacs-nox \
      texlive-latex-recommended texlive-fonts-recommended \
      make git rsync curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Hugo extended, matching the image architecture.
RUN curl -fsSL "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-${TARGETARCH}.tar.gz" \
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

WORKDIR /site
