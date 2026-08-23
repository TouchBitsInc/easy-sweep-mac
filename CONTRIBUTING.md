# Contributing

The rules below exist because a contributed data file drives a program that
deletes things. Each one is enforced by CI; the reasoning is here so a rejection
is explicable rather than arbitrary.

The catalog is the list of cleanable locations: paths, what they are, and how to
describe them. It is the one part of this app that benefits from outside
contributions — cache locations are long-tail knowledge, and someone running Nix
or Unity knows their paths better than we do. It is destined for a public repo
that takes pull requests.

Everything else stays private. Nobody contributes a better recursive size walk,
and every pull request against `Cleaner` or `PathGuard` would need reviewing as
a security review rather than a code review. The app-leftover matching tiers
stay closed for a different reason: they are the difference between this and
AppCleaner.

The rules below exist because a contributed data file drives a program that
deletes things.

## The trust boundary

CI can check shape, containment, roots and symbols. **It cannot check the claim
that matters** — that `~/.foo/cache` is really a regenerable cache — because the
tool isn't installed on the runner. Every rule here is an attempt to shrink what
has to be taken on trust, and none of them removes it.

Two consequences:

- Pull requests require a link to upstream documentation showing the path is a
  cache and how it regenerates. A path with no citation is not mergeable.
- The app depends on this package **pinned to an exact version**, and must never
  fetch the catalog at runtime. A remote file naming deletion paths is a
  supply-chain target, and `PathGuard` would be the only thing left between a
  merged typo and someone's home directory.

## Schema

One file per category — `developer.json`, `aiTools.json`, `browsers.json`,
`multimedia.json`, `system.json`.

```json
{
  "id": "bun",
  "name": "Bun",
  "detail": "Downloaded packages for bun install. Refetched on the next install.",
  "paths": ["~/.bun/install/cache"],
  "risk": "safe",
  "symbol": "shippingbox.fill",
  "brandColor": "#000000",
  "granular": false
}
```

`id` is permanent and must be unique across every file. It keys the app-side
safety table below, so renaming one silently drops that entry's local settings.

`brandColor` is the **published brand hex, unmodified**. Do not adjust it for
legibility — `Theme.brand(_:)` lifts near-black values app-side so the hue is
preserved rather than substituted. Omit it if the project brands itself black;
five tools sharing one lifted grey says less than the size-rank palette.

## Sections

`Category` in `Entry.swift` is the list of sections, and **the case order is the
order they are shown in** — there is no rank field anywhere else, so moving a
case moves the section. One thing travels with it: `isPinned`, which marks a
section that leads the list and stays there because every Mac has it whatever is
installed. `pinned` and `unpinned` are those two groups. Only `system` is
pinned; the rest describe installed tooling, which is what makes them reasonable
for an app to let someone put away. Adding a section means a case, a
`<rawValue>.json` beside the others, and deciding `isPinned` — the switch is
exhaustive so it cannot be skipped.

## What contributors cannot set

These live in the app, keyed by `id`, and are deliberately absent from the
schema:

- **`allowsUnattendedClean`** — the flag that lets the menu bar's one-click
  clean and the low-space notification take a target *without the user ticking
  anything*. It defaults to `false` and is granted per target. If this were
  contributable, a merged pull request would widen what gets deleted
  automatically on every machine running the app.
- **`specialCleaner`** — routes simulator device sets through `simctl` instead
  of file removal. Wrong here corrupts CoreSimulator's registry.

`risk` **is** contributable, but absent means `risky`, not `safe`. It feeds the
unattended guard (`allowsUnattendedClean && risk == .safe`) and the confirmation
dialog's wording. Since `allowsUnattendedClean` is app-side and defaults false, a
contributed entry can never reach the automatic path — but a mislabelled `safe`
still misleads someone at the moment they confirm a deletion.

## Paths

**Several locations for one tool is normal.** `paths` is an array; `npm-cache`,
`yarn-pnpm` and `composer` each name two. Targets whose paths don't exist are
hidden automatically, so listing a path that only some setups have is free.

**Versioned directories: name the parent, set `granular`.** Where the version is
the whole leaf — `iOS DeviceSupport/iPhone17,4 26.5.2 (23F84)`,
`Caches/JetBrains/<product><version>` — point at the parent and let the scanner
enumerate. The user gets a per-version size and a tickable row for each, which a
wildcard cannot give them. `jetbrains`, `electron` and `nuget` all work this way.

**Wildcards are for versioned names among unrelated siblings**, and nothing else:

```
~/Library/Caches/Google/Chrome/            ← not ours
~/Library/Caches/Google/Chrome Beta/       ← not ours
~/Library/Caches/Google/AndroidStudio2024.1/  ← ours
```

Naming `Caches/Google` would sweep Chrome. Naming the exact folder breaks on
every upgrade. So `~/Library/Caches/Google/AndroidStudio*` — with these limits:

- `*` matches **within one path segment**. `**` is not representable, so a
  pattern cannot descend arbitrarily.
- **No wildcard in the first two segments.** Every pattern needs a literal
  anchor, `~/*` is rejected outright, and `grantRoots` stays computable without
  touching the disk.
- Matches are capped. A pattern resolving to hundreds of directories is a bug or
  an attack, not a cache.
- Expansions pass through `PathGuard` and the existence filter exactly as
  literal paths do.

CI rejects a wildcard where parent-plus-`granular` would have worked. Left
unchecked, contributors reach for `*` by habit and the per-version selection that
makes the Developer section useful quietly disappears.

## Grant roots — one entry, one folder

A *grant root* is the folder the sandboxed Mac App Store build must ask the user
for: `Library/Developer`, `Library/Caches`, `.npm`. `CleanTarget.grantRoots`
derives them from `paths` rather than taking a declaration, so **adding a path
silently adds a permission the store build will demand**.

**Every entry must sit under exactly one root.** An entry spanning two is half
usable under the sandbox — one folder granted, the other not — and there is no
way to show that honestly on a single row. Four entries currently break this and
each splits in two:

| Entry | Roots |
|---|---|
| `android` | `.android`, `Library/Caches` |
| `yarn-pnpm` | `Library/Caches`, `Library/pnpm` |
| `composer` | `.composer`, `Library/Caches` |
| `claude-caches` | `.claude`, `Library/Caches` |

Allowed roots: `Library/Caches`, `Library/Developer`,
`Library/Application Support`, `Library/Logs`, `Library/Containers`,
`Library/pnpm`, and dot-directories directly under `~`. Anything else fails CI. This is also why a wildcard may not appear in the first two
segments — the root has to be computable without touching the disk.

### Categories are not grant roots

The five sections are a reading order, not a permission boundary. Measured
across the current catalog:

| Category | Distinct roots |
|---|---|
| `developer` | 22 |
| `aiTools` | 8 |
| `browsers` | 1 |
| `multimedia` | 2 |
| `system` | 4 |

Thirty in total. Making each section one folder would mean thirty
sections, most of them holding a single row, so the sections stay as they are and
the **sandboxed build ships a subset instead**:

- **Free build** — unsandboxed, all five sections, every root.
- **Mac App Store build** — only roots obtainable with one grant each:
  `Library/Developer`, `Library/Caches`, `~/.cache`. Entries under dot-directory
  roots are not offered at all.

That is a real product difference, not a technicality: most package-manager
caches live in dot-directories, so the store build is a narrower app. It is also
already true — the app's own store build carries a warning to that effect.

Contributors do not need to think about this. Adding an entry under a
dot-directory root is fine; it simply won't appear in the store build.

## Writing `detail`

It is the sentence someone reads immediately before deleting, so it is doing
safety work.

- State **what regenerates it and how**: "Refetched on the next install",
  "Xcode rebuilds these on the next build".
- Never write "safe to delete". `risk` carries that, and the reader deserves the
  mechanism rather than a reassurance.
- One or two sentences. It renders in two lines under the name.
- English is the source text; it is not currently localized.

## Validation

CI enforces, and each rule maps to a way this has already gone wrong or could:

| Check | Why |
|---|---|
| No path contains another entry's path | `~/.cache/uv` under `xdg-cache`'s `~/.cache` double-counts bytes in the section total and the bar |
| `id` unique across all files | Ids key the app-side safety table |
| Grant root in the allowlist | An unexpected root changes what the sandboxed build must ask for |
| Wildcard limits above | Keeps patterns anchored and grant roots static |
| `symbol` resolves via `NSImage(systemSymbolName:)` | An unknown SF Symbol renders as **nothing**, silently — no placeholder |
| `brandColor` parses as 6-digit hex | Malformed colour otherwise falls back invisibly |
| `category` is known | Unknown categories are skipped at decode; CI catches them earlier |

Decoding is **per entry, skipping failures** rather than whole-file. One
malformed record from a newer catalog must not blank an entire section on an
older build of the app.

## Consuming it

The app maps `EasySweepCatalog.Entry` to `CleanTarget`, applying the app-side safety table
by `id`. The catalog is a Swift package so others can `import` it, but this app
pins an exact tag — the pin is the review gate, and bumping it is a deliberate
act, not a resolution side effect.

## Releasing

**Every change to the catalog gets a tag, and the version goes up by 0.0.1.**
`1.2.0` → `1.2.1` → `1.2.2`, whether the change is one entry or twenty.

Two reasons it works this way. Consumers pin an **exact** version, so a merged
pull request reaches nobody until a tag exists — an untagged change is not
released, it is just committed. And a uniform patch step removes the only
question a contributor would otherwise have to answer: whether adding a location
is a patch or a minor. It never matters here, because the pin is exact and every
consumer moves deliberately either way.

Reserve a minor bump (`1.2.x` → `1.3.0`) for a change to the **schema or the
Swift API** — a new `Entry` field, a new `Category` case, a change to how paths
resolve. Those are the changes that can fail to compile in a consumer, and the
version should say so before anyone bumps a pin.

**Tags for the app's own downloads are prefixed `app-v`** and are not catalog
versions. This repository serves the website and the notarized `.dmg` as well as
the package, and SwiftPM reads any tag parsing as semver with an optional leading
`v` as a package version — so a release tagged `1.0.0` would appear to every
consumer as a catalog version that isn't one. The prefix keeps the two sets of
tags independent.
