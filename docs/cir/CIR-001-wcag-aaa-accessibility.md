# CIR-001: Bring the site to WCAG AAA conformance

## Intent

Make the personal website conform to the Web Content Accessibility
Guidelines (WCAG) 2.2 at Level AAA — the strictest conformance level —
across every page and blog post, so the content is usable by the widest
possible range of readers and assistive technologies.

## Behavior

- GIVEN any text or user-interface element
- WHEN it is rendered in either the light or the dark theme
- THEN its contrast against its background is at least 7:1 for text and
  at least 3:1 for focus and interface boundaries (1.4.6)

- GIVEN a reader using the keyboard only
- WHEN they tab through a page
- THEN a visible focus ring is shown, a skip link is available, and every
  interactive target is at least 44 by 44 pixels (2.4.7, 2.4.1, 2.5.5)

- GIVEN a figure in a blog post
- WHEN it is read by a screen reader
- THEN the image carries descriptive alt text that differs from the
  visible caption, and complex diagrams have an equivalent in nearby text
  (1.1.1)

- GIVEN a blog post that uses an abbreviation or specialised jargon
- WHEN a reader needs its meaning
- THEN the abbreviation's expansion is available on first use and the
  jargon is defined in the post's Glossary (3.1.4, 3.1.3)

- GIVEN a reader who wants the gist without the full technical article
- WHEN they open a post
- THEN a plain-language "In short" summary appears at the top (3.1.5)

- GIVEN a reader on a blog post
- WHEN they want to know where they are in the site
- THEN a breadcrumb trail (Home / Blog / post) is present (2.4.8)

- GIVEN the colour palette is derived from Modus, which guarantees 7:1
  only against its main background
- WHEN code blocks and tag chips are rendered
- THEN they sit on the main background (delineated by a border) rather
  than a tinted surface, so their syntax colours keep 7:1

- GIVEN an existing behaviour not related to accessibility (routing,
  feed generation, permalinks, the light/dark/auto toggle logic)
- WHEN the accessibility changes are applied
- THEN that behaviour SHOULD NOT change

- GIVEN common words and everyday idioms (for example "chess match")
- WHEN a post is annotated
- THEN they are deliberately NOT marked, so the prose is not buried in
  markers; only genuine abbreviations and specialised jargon are treated

## Constraints

- Content is authored in Org mode and exported to Hugo Markdown by
  ox-hugo; accessibility helpers had to work through that pipeline. They
  are implemented as shared Org macros (`abbr`, `dfn`) and a
  `plainsummary` special block in `org/ox-hugo-setup.org`, included by
  every post, rather than as hand-written HTML per file.
- The generated `content/` directory is regenerated and git-ignored, so
  no fix could live there; all changes live in tracked sources
  (`blog/*.org`, `layouts/`, `static/css/`, `org/`).
- The existing light/dark/auto theme toggle and the site's minimal visual
  design were preserved.

## Decisions

- **Palette: adopt Prot's Modus themes (modus-operandi light,
  modus-vivendi dark).** They are purpose-built to meet 7:1. Every colour
  used was verified against its actual background with a contrast script,
  not taken on faith.

- **Use the pure main backgrounds (white / black), not the dimmed
  variants.** We measured all three options. Modus guarantees 7:1 only
  against `bg-main`; on `bg-dim` the muted greys and several syntax
  tokens fall below 7:1, and on `bg-inactive` whole hue families have no
  compliant Modus variant. Keeping the soft off-white look was therefore
  incompatible with AAA-on-Modus. We chose pure backgrounds and separate
  code/tag surfaces with a border instead of a fill. This is a visible
  aesthetic change from the previous Onenord palette and was accepted as
  the cost of the 7:1 guarantee.

- **Language tier (3.1.3–3.1.5): implement all three, every post.** The
  W3C advises against requiring full AAA site-wide, largely because of
  3.1.5; the site owner chose full coverage anyway. To avoid harming
  readability, jargon is defined in a curated per-post Glossary
  (a description list — techniques G101/H40) rather than as inline
  tooltips on every term, and only genuine abbreviations are marked
  inline. Summaries were drafted with assistance and are the author's to
  refine.

- **3.1.6 Pronunciation: not applicable.** This criterion applies only
  where a word's meaning is ambiguous without its pronunciation
  (heteronyms). The posts are technical prose where context always
  disambiguates, so no pronunciation mechanism is needed.

- **Breadcrumb and navigation target sizes: rely on the 2.5.5
  equivalent-control exception where reasonable.** Breadcrumb "Home" and
  "Blog" links duplicate the always-present 44px header navigation, so
  they are exempt and kept compact; the header links, toggle, and post
  links were enlarged to 44px.

- **Theme-toggle accessible name.** The button's descriptive label is set
  by JavaScript; a static `aria-label="Color theme"` was added so it has
  a name even before or without scripting (4.1.2).

- **Verification.** Three layers were used. First, a contrast script over
  the built CSS confirmed every text and background pair is at least 7:1
  in both themes. Second, a static HTML audit (lang, title, single h1,
  heading order, image alt, skip link, landmarks, tabindex) across all 20
  content pages was clean. Third, pa11y (HTML_CodeSniffer driving a real
  headless Chromium) was run at the WCAG2AAA standard against every
  content page; it initially reported two duplicate-id failures (F77)
  where ox-hugo generated the same anchor id for two identically named
  figures and two identically named code blocks. Both were fixed by
  giving the duplicates distinct names, after which the pa11y sweep
  reported zero errors across all 20 pages. A manual keyboard and
  screen-reader pass in a real browser is still recommended as a final
  human check; pa11y's remaining warnings and notices are advisory
  manual-review items, not failures.

## Date

2026-07-04
