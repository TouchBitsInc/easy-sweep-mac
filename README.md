# Easy Sweep

The public home of [Easy Sweep](https://easysweep.app), a macOS disk cleaner.
The app itself is closed source. What lives here is `EasySweepCatalog`: a
curated list of the caches and generated files that developer tools, AI CLIs,
desktop apps and macOS leave behind — where they are, what they hold, and
whether losing them costs anything.

Data, not a cleaner. This package tells you *where* things are; it deletes
nothing and asks for no permissions.

```swift
import EasySweepCatalog

for entry in EasySweepCatalog.all {
    print(entry.name, entry.paths)   // "Homebrew" ["~/Library/Caches/Homebrew"]
}

EasySweepCatalog.entries(in: .developer)
```

The catalog is public because this is the part worth contributing to. Cache
locations are long-tail knowledge — someone running Nix or Unity knows their
paths better than we do. The app resolves this package at an exact version,
so whatever is merged here reaches it when someone bumps that version.

## Adding a tool

Open a pull request against the JSON file for the section it belongs in:

```json
{
  "id": "bun",
  "name": "Bun",
  "detail": "Downloaded packages for bun install. Refetched on the next install.",
  "path": "~/.bun/install/cache",
  "risk": false,
  "symbol": "shippingbox.fill",
  "color": "#000000"
}
```

**Include a link to upstream documentation** showing the path is a cache and how
it regenerates. CI can check the shape of an entry; it cannot check that claim,
because the tool isn't installed on the runner. That citation is the only thing
standing in for it.

Read [CONTRIBUTING.md](CONTRIBUTING.md) before a first pull request — it covers
the rules CI enforces and, more usefully, why each exists.

The short version:

- **One entry, one folder.** Every path in an entry must sit under the same
  top-level location, because that is the permission a sandboxed app has to ask
  for. Entries spanning two are half usable and get split.
- **No path may contain another's.** Two entries covering nested paths
  double-count the bytes wherever sizes are totalled.
- **Say what regenerates it.** `detail` is what someone reads immediately before
  deleting. "Refetched on the next install", never "safe to delete".
- **Wildcards are a last resort.** Where a version is the whole folder name,
  name the parent and give it `"subfolders": ["*"]` instead — the app shows a
  size per version.

## Section presentation

`Catalog/categories.json` names the SF Symbol and localized title for each
section. `Category.symbol` returns the configured symbol, falling back to a
compiled-in name if it doesn't exist on the running macOS. `Category.localizedName(for:)`
resolves a BCP-47 locale through an exact regional/script match, its language,
and then English.

Each section's `localizations` is a map of locale identifiers to objects rather
than a fixed set of language fields. That keeps adding a supported language
data-only, and leaves room for more localized presentation fields later without
changing the top-level category shape.

Each catalog entry keeps English in `name` and `detail` for compatibility and
stores translated copy in its own `localizations` map. Use
`Entry.localizedName(for:)` and `Entry.localizedDetail(for:)`; locale matching
accepts regional and script variants before falling back to English.

## Cleaning safety

`risk` is one conservative Boolean decision. `false` means the reviewed target
may be cleaned automatically; `true` means it requires manual confirmation.
Every entry must declare the field; a missing value fails decoding.
Broad wildcard targets, app-wide state folders, offline or synced content,
active staging areas, and stores that can contain locally produced artifacts
all use `true`.

Consumers derive automatic cleaning directly as `!risk`. Risky entries require
manual confirmation; the catalog does not publish a second warning or safety
field that could disagree with the Boolean decision.

How removal is performed still belongs to the consuming app. For example,
simulator device sets must go through `simctl`, not raw filesystem deletion.

## Licence

MIT.
