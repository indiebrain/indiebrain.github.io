# ADR-001: Publish the site with ox-hugo and Hugo

## Status

Proposed

## Context

The site was built with org-page, an Emacs package that is no longer
maintained. The sources are Org files (about page, résumé, and a small
blog) on the `source` branch; org-page generated HTML onto `master`,
which GitHub Pages serves at aaronkuehler.com.

Two hard constraints shape any replacement:

1. **Keep authoring in Org mode.** The whole content set is Org, and the
   author writes in Emacs.
2. **Preserve the existing URLs**, especially blog permalinks of the form
   `/blog/YYYY/MM/DD/<slug>/`, which are linked from other sites and
   distributed in feeds. Inspection of `master` also revealed that
   org-page had left several *historical* URLs live: posts that were
   re-dated over time kept every past path, and one post has a typo'd URL
   (`installing-coreboot---lenovo-thinkpax-x220`) that still resolves.
   These must not start returning 404s.

The feed lives at `/rss.xml` and the custom domain is pinned by a
`CNAME` file — both are relied upon externally.

## Decision

Author in Org; export to Hugo-flavored Markdown with **ox-hugo**; build
the static site with **Hugo**; deploy to GitHub Pages from a GitHub
Actions workflow.

- **ox-hugo** preserves full Emacs Org fidelity on the authoring side
  (Org export, Babel, image handling) rather than relying on a
  third-party Org parser.
- **Hugo** reproduces the permalink scheme exactly via
  `permalinks.blog = "/blog/:year/:month/:day/:slug/"`, with per-post
  `slug` and `date` supplied from Org `#+HUGO_SLUG` and `#+DATE`.
- Historical and typo'd URLs are preserved as redirect stubs using Hugo
  `aliases`, populated per post from `#+HUGO_ALIASES`.
- The feed is kept at `/rss.xml` by setting the RSS output `baseName`,
  and `CNAME` is served from `static/`.
- Org remains the single source of truth: `content/` (Markdown) and
  `public/` (HTML) are generated in CI and never committed.

## Consequences

Positive:

- Authoring stays in Org and in Emacs.
- Every existing URL — canonical, historical, and the typo — keeps
  working; nothing distributed in the wild breaks.
- Hugo provides feeds, sitemaps, taxonomies, and theming without a
  bespoke generator to maintain.
- CI builds are reproducible and need no local toolchain.

Negative / costs:

- Two-step build (Emacs export, then Hugo) with more moving parts than a
  single tool, and Emacs must run in CI.
- The visual theme must be reimplemented as Hugo layouts (the prototype
  ships intentionally minimal layouts).
- Some one-time content cleanup is required: `#+KEYWORDS` lines export
  into malformed front matter, `#+TAGS` are not yet mapped to Hugo tags,
  and ox-hugo relocates post images under `/ox-hugo/` rather than their
  original `/assets/...` paths.
- GitHub Pages must be switched to deploy from GitHub Actions rather than
  the `master` branch; `master` then becomes vestigial.

## Date

2026-07-03
