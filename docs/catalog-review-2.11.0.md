# Catalog 2.11.0 review

This release adds one field.

## `keeps`

Some folders hold one copy per version, and the newest copy is the one in use.
The consuming app has spared the newest Device Support build from unattended
cleaning since 1.0, keyed on the entry id. That rule now lives in the data:
`"keeps": "newest"` on an entry means a clean nobody is watching removes every
row but the most recently modified one. A box the user ticks by hand can still
take it. The three Device Support entries declare it, and `KeepsTests` pins
that they do.

The field is decoded strictly. An entry carrying a `keeps` value a build does
not recognise fails to decode and is dropped from that build, rather than
reading as "keep nothing" — which would have an older build clean the very row
a newer catalog says to keep.

## Withdrawn in 2.11.1

2.11.0 also added `edge-updater-staging`, pointing at
`~/Library/Application Support/Microsoft/EdgeUpdater/apps/msedge-stable`. The
Homebrew cask confirms only the `EdgeUpdater` folder; the `apps/msedge-stable`
layout beneath it had no source, and a review found counter-evidence in the
Chromium updater's own code, which documents its `apps` directory as a demo
path. The entry is withdrawn until someone with Edge installed confirms where
staged copies live. The catalog is back at 231 entries.
