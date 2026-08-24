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
  "risk": "safe",
  "symbol": "shippingbox.fill",
  "brandColor": "#000000"
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

## What isn't here, deliberately

Whether something may be deleted *without asking*, and whether removal needs a
tool such as `simctl` rather than the filesystem, are not fields in this schema.
They live in the consuming app, keyed by entry id. A pull request here can add a
location; it cannot widen what an app deletes automatically.

## Licence

MIT.
