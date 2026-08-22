# easysweep.app

The marketing site, served from this folder. Plain HTML and CSS — no build step,
no dependencies, no framework. Open `index.html` in a browser and what you see is
what deploys.

```
web/
  index.html          the product page
  privacy.html        privacy policy — required by App Store review
  terms.html          licence terms
  support.html        support page — required by App Store review
  404.html            served by Cloudflare Pages on a miss
  css/styles.css      the whole design system, one file
  js/main.js          nav border, scroll reveal, one-open-at-a-time FAQ
  assets/             app icon renders + the Open Graph card
  assets/shots/       app screenshots
  _headers            security and cache headers (Cloudflare Pages)
  _redirects          /download alias + short URLs (Cloudflare Pages)
  robots.txt sitemap.xml llms.txt
```

The page is dark-only on purpose. A developer tool reads better committed to one
look than split across a compromised pair, and it means no theme code to keep in
sync. Every colour is a token at the top of `styles.css`.

## Local preview

Any static server. Paths are absolute (`/css/...`), so opening the file directly
with `file://` will not resolve them — use a server:

```sh
cd web && python3 -m http.server 8080
# then http://localhost:8080
```

## Deploying — Cloudflare Pages

The site lives in `TouchBitsInc/easy-sweep-mac`, which is public and holds the
catalogue package. Cloudflare therefore needs no access to the application
itself — the scan/clean engine and uninstall matching stay in the private
`easy-sweep` repo and are not visible here.

Keep the images small. SwiftPM mirror-clones this whole repo (`+refs/*:refs/*`,
full history, no shallow) to resolve the package, so anything committed here is
downloaded by every consumer forever, including blobs later replaced. That is why
the screenshots are JPEG rather than PNG: it took the site from 7.3 MB to 740 KB.
Re-encode any replacement with `sips -s format jpeg -s formatOptions 90`.

One-time setup:

1. **Cloudflare dashboard → Workers & Pages → Create → Pages → Connect to Git**,
   and pick `TouchBitsInc/easy-sweep-mac`.
2. Build settings:
   | Setting | Value |
   |---|---|
   | Framework preset | None |
   | Build command | *(leave empty)* |
   | Build output directory | `web` |
   | Root directory | `/` |
3. **Settings → Builds → Build watch paths**, include only `web/*`. Without this,
   every commit to the app source triggers a pointless deploy.
4. **Custom domains → Set up a domain**, `easysweep.app`, then add `www` as a
   redirect to the apex.
5. Production branch: `main`.

`_headers` and `_redirects` are read from the build output directory, so they
belong at `web/`'s top level — where they are. They do nothing when previewing
locally.

### A note on the production branch

Pages deploys from this repo's `main`. The app itself ships from the `release`
branch of the *private* repo, so marketing copy for an unreleased feature can go
live before the feature does. Hold site changes describing new features until the
app actually ships.

## The download link

The button points at GitHub Releases rather than a file in this repo, for two
reasons: Cloudflare Pages refuses individual files over 25 MiB, and a committed
binary stays in git history permanently.

The URL appears in **five places** — grep before changing it:

```sh
grep -rn "releases/latest/download" web/
```

`index.html` (hero, editions card, both pricing cards, closing CTA) and
`_redirects`. The `_redirects` entry also gives you `easysweep.app/download` as a
stable short link, which is the one worth putting in a README or a tweet.

> [!IMPORTANT]
> **Tag app releases with a prefix, e.g. `app-v1.0.0`.** This repo is also the
> Swift package the app pins to an exact version, and SwiftPM reads git tags as
> package versions — but *only* tags that parse as semver, with an optional
> leading `v`. A release tagged `1.0.0` would therefore appear to every consumer
> as a catalogue version that isn't one, and would eventually collide with a real
> catalogue release wanting that number. A tag like `app-v1.0.0` does not parse
> as a version, so SwiftPM ignores it entirely and both namespaces stay clean.
>
> **The MIT licence covers the catalogue sources, not the released app.** A
> proprietary DMG in the Releases of an MIT-licensed repo invites the reading
> that the licence extends to the application, which it does not — see the root
> `CLAUDE.md`. The repo README must scope this explicitly, and release notes
> should not imply otherwise.

## Still to fill in

- [ ] **Screenshots.** `assets/shots/*.png` are placeholders at the right
      dimensions (2400×1560), as JPEG. Capture the Developer section, the
      Applications table and the Automation rules table on a Retina display,
      window only (`⌘⇧4`, then Space), then re-encode to JPEG q90 and drop them
      in under the same names.
- [ ] **App Store URL.** `index.html` has the editions card marked
      `TODO(website)`, currently a non-link reading "Coming soon". Swap in
      `https://apps.apple.com/app/easy-sweep/id…` once the app clears review.
- [ ] **`support@easysweep.app` must exist.** It is cited on the support page,
      the privacy policy and the terms, and App Store review will check that
      support and privacy URLs resolve. Cloudflare Email Routing forwards it for
      free.
- [ ] **Confirm the price.** `$9.99` appears once, in the pricing section of
      `index.html`. It must match the Lemon Squeezy product and the App Store
      in-app purchase, neither of which is registered yet.
- [ ] **Governing law** in `terms.html` says Ontario, Canada. Change it if that
      is wrong for TouchBits Inc.

## Accuracy

The copy makes specific claims — what the app refuses to delete, how sizes are
measured, what the sandbox costs the App Store edition. Every one of them traces
to an invariant in the root `CLAUDE.md` and is pinned by a test in
`EasySweepTests`. If one of those invariants ever changes, the claim here becomes
false, so treat this folder as part of the surface a behaviour change has to
update.
