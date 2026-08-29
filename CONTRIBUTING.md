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
`messaging.json`, `multimedia.json`, `system.json`.

```json
{
  "id": "bun",
  "name": "Bun",
  "detail": "Downloaded packages for bun install. Refetched on the next install.",
  "path": "~/.bun/install/cache",
  "risk": false,
  "symbol": "shippingbox.fill",
  "color": "#000000",
  "localizations": {
    "fr": {
      "name": "Bun",
      "detail": "Paquets téléchargés pour bun install. Retéléchargés lors de la prochaine installation."
    }
  }
}
```

`name` and `detail` are the English fallback. `localizations` is an expandable
map keyed by BCP-47 locale identifiers; every supported locale should have both
fields, while English may rely on the top-level fields. Keep paths, commands,
product names and quoted identifiers unchanged inside a translation. Consumers
use `Entry.localizedName(for:)` and `Entry.localizedDetail(for:)`, which fall
back from a regional or script locale to its language and then to English.

**One `path` per entry, and it is literal.** That single path is the folder a
sandboxed app has to be granted, so it must be readable without listing the
disk — which is why a wildcard may never appear in it. An entry whose locations
live under two different parents is two entries; `composer` and
`composer-library` are the standing example.

**`subfolders` is what to take inside that path, and each one is a row the user
ticks.**

```json
{ "path": "~/.gradle", "subfolders": ["caches", "daemon", "wrapper"] }
{ "path": "~/Library/Developer/Xcode/DerivedData", "subfolders": ["*"] }
{ "path": "~/Library/Application Support", "subfolders": ["*/Code Cache"] }
```

- Absent means the folder itself, one row.
- `["*"]` means every child, a row each.
- A named list gives a row per name, and any segment may carry a single `*`,
  because `path` already supplies the literal anchor.

There is no `granular` flag and no `paths` array; both were folded into this in
2.0.0.

`id` is permanent and must be unique across every file. Consumers persist rules
and history against it, so renaming one silently disconnects those records.

`color` is the **published brand hex, unmodified**. Do not adjust it for
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

### A section's icon

`categories.json` names the SF Symbol each section is drawn with, keyed by the
same id as its entry file:

```json
{
  "multimedia": { "symbol": "movieclapper" }
}
```

It is contributable for the reason `Entry.symbol` is — which glyph reads as
"media" is a judgement, and this is where judgements about the catalog are
collected. Two guards sit under it, because an unknown SF Symbol name renders as
*nothing at all* rather than a placeholder: `builtInSymbol` in
`CategoryPresentation.swift` is a compiled-in name per section, and `symbol`
returns it whenever the file names none or names one the running macOS does not
have. That second case is not something CI here can catch — the runner's OS is
not the user's — which is why the fallback exists rather than a validation rule
alone.

The section title is in this file too: `categories.json` uses the same
locale-keyed shape as entries. Add a new locale there when adding one to the
app; `Category.localizedName(for:)` applies the same regional, script and
English fallback order.

## Automatic cleaning

`risk` is the single cleaning decision. `false` means the reviewed target may be
cleaned automatically; `true` means it requires manual confirmation. Absent
is invalid; every bundled entry declares the Boolean explicitly so the decision
is visible beside the path. There is no migration or fallback safety schema.

Use `false` only when every selected path contains regenerable data, deletion
cannot remove a user's sole copy, and the target is narrow enough to audit
without inspecting the machine. Broad app-wide wildcards, synced or offline
content, active staging areas, and stores that can contain locally produced
artifacts use `true`.

Do not add a parallel warning, safe, or allowlist field. Consumers derive
automatic cleaning as `!risk`; `true` is the complete signal to require manual
confirmation.

**`specialCleaner` remains app-side.** It routes simulator device sets through
`simctl` instead of file removal; getting that wrong can corrupt
CoreSimulator's registry.

## Paths

**Several locations for one tool is normal.** `paths` is an array; `npm-cache`,
`yarn-pnpm` and `composer` each name two. Targets whose paths don't exist are
hidden automatically, so listing a path that only some setups have is free.

**Versioned directories: name the parent, and give it `["*"]`.** Where the version is
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
- **No wildcard in `path`, ever.** The entry's own path is the literal anchor,
  so `grantRoot` stays computable without touching the disk. Wildcards live in
  `subfolders`, which are already inside a folder the entry named in full.
- Expansion is capped at 512 folders — enough that one row per installed app is
  never truncated, low enough that nothing runs away.
- Expansions pass through `PathGuard` and the existence filter exactly as
  literal paths do.

Prefer a named subfolder to a wildcard where the name is stable: `["caches",
"daemon"]` says what will go, where `["*"]` says "whatever is in there".

## Grant roots — one entry, one folder

A *grant root* is the folder the sandboxed Mac App Store build must ask the user
for: `Library/Developer`, `Library/Caches`, `.npm`. It is derived from the
entry's single `path` rather than declared, so **adding an entry silently adds a
permission the store build will demand** — which is why one entry has exactly
one root, now by the shape of the schema rather than by a test.

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

The six sections are a reading order, not a permission boundary. Measured
across the current catalog:

| Category | Distinct roots |
|---|---|
| `developer` | 33 |
| `aiTools` | 10 |
| `browsers` | 2 |
| `messaging` | 4 |
| `multimedia` | 4 |
| `system` | 6 |

Forty-eight distinct roots in total, with the `Library` ones shared between
sections. Making each section one folder would mean dozens of sections, most of
them holding a single row, so the sections stay as they are and the **sandboxed
build ships a subset instead**:

- **Free build** — unsandboxed, all six sections, every root.
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
- English is the source text; every supported locale supplies its own copy.

## Validation

CI enforces, and each rule maps to a way this has already gone wrong or could:

| Check | Why |
|---|---|
| No path contains another entry's path | `~/.cache/uv` under `xdg-cache`'s `~/.cache` double-counts bytes in the section total and the bar |
| `id` unique across all files | Ids key persisted rules and cleaning history |
| `risk` is an explicit Boolean | Missing or ambiguous safety decisions fail decoding |
| Grant root in the allowlist | An unexpected root changes what the sandboxed build must ask for |
| Wildcard limits above | Keeps patterns anchored and grant roots static |
| `symbol` resolves via `NSImage(systemSymbolName:)` | An unknown SF Symbol renders as **nothing**, silently — no placeholder |
| `color` parses as 6-digit hex | Malformed colour otherwise falls back invisibly |
| `category` is known | Unknown categories are skipped at decode; CI catches them earlier |

Decoding is **per entry, skipping failures** rather than whole-file. One
malformed record from a newer catalog must not blank an entire section on an
older build of the app.

## Consuming it

The app maps `EasySweepCatalog.Entry` to `CleanTarget`; `autoClean` is derived as
`!risk`. The catalog is a Swift package so
others can `import` it, but this app pins an exact tag — the pin is the review
gate, and bumping it is a deliberate act, not a resolution side effect.

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
