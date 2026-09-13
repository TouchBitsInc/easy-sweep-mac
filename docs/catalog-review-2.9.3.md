# Catalog 2.9.3 review corrections

This follow-up reviews the 37 additions and ten browser extensions released in
2.9.2. It checks their source evidence, selected roots and leaves, loss and
recovery consequences, localized descriptions, and neighboring protected data.
The catalog remains at 205 entries. No category, API, or cleanup engine changes
are required.

## Corrections

### Yarn Berry recovery

The original description treated the global package store as files that would
return when a project needed them. [Yarn's Plug'n'Play documentation](https://yarnpkg.com/features/pnp)
states that the runtime loader directly references packages at their cache
paths. Removing this cache can therefore stop already installed projects from
running; ordinary execution does not restore the missing packages.

The description now tells the user to restore packages with `yarn install`
before running projects. This correction covers all 16 supported languages.
The entry remains cautious, so automatic cleaning cannot select it.
[Yarn's cache cleaner](https://github.com/yarnpkg/berry/blob/master/packages/plugin-essentials/sources/commands/cache/clean.ts)
confirms that removal of the shared cache is supported.

### Puppeteer recovery and selection boundary

The original description mentioned a future installation without giving the
required action. [Puppeteer's troubleshooting documentation](https://pptr.dev/troubleshooting)
provides `npx puppeteer browsers install` to restore downloaded browsers. The
description now includes that command in every supported language. This entry
also remains cautious.

The selection now names the five distributions in Puppeteer's [browser enum](https://github.com/puppeteer/puppeteer/blob/main/packages/browsers/src/browser-data/types.ts):
`chrome`, `chrome-headless-shell`, `chromium`, `firefox`, and `chromedriver`.
Each selected browser directory includes its versions and its own `.metadata`,
matching the [upstream cache layout](https://github.com/puppeteer/puppeteer/blob/main/packages/browsers/src/Cache.ts).
Unknown sibling directories and root-level files are excluded. Removing a
browser's metadata together with its installations avoids leaving aliases that
refer to deleted versions.

## Review outcome and limits

The remaining added entries retain the paths and risks documented in the
[2.9.2 review](catalog-review-2.9.2.md). In particular, IINA screenshots,
Office sideloaded add-ins, editor recovery data, browser profiles, credentials,
and installed language toolchains remain outside the new selections.

The source evidence has different strengths. Tool-owned paths such as
python-build's download cache and IINA's thumbnail cache are named in their
owners' documentation or source. Figma and Obsidian rendering leaves, and the
Chromium-derived browser extensions, combine documented product roots with
engine-defined cache names. Those remain explicitly identified inferences;
they were not verified by running every third-party application.

This is a review of the 2.9.2 expansion, not a fresh audit of the preceding 168
entries or the deferred candidate list. No user cache was deleted to validate
the changes. The filesystem fixtures check all five Puppeteer distributions,
browser metadata, and unknown siblings, alongside the existing checks that
cache bytes are selected once and protected data is excluded.
