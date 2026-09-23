# Catalog 2.11.0 review

This release adds one field and one entry. The catalog grows from 231 to 232
entries.

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

## Edge updater staging

| Entry | Path | Risk | Source |
|---|---|---|---|
| `edge-updater-staging` | `~/Library/Application Support/Microsoft/EdgeUpdater/apps/msedge-stable/*`, keeps newest | safe | [cask `microsoft-edge`](https://formulae.brew.sh/cask/microsoft-edge) lists `~/Library/Application Support/Microsoft/EdgeUpdater` among the folders the browser creates. The updater stages one full copy of the browser per downloaded version under `apps/msedge-stable`; after Edge installs an update the previously staged copy is left behind. The newest copy may be an update not yet applied, which is why it is kept on the unattended paths. A copy removed by hand is downloaded again by the updater. |
