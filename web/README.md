# easysweep.app

The Easy Sweep website. Plain HTML and CSS — no build step, no dependencies,
nothing to install.

```
web/
  index.html                    the product page
  privacy.html terms.html       legal
  support.html                  help and contact
  404.html                      served on a miss
  css/styles.css                the whole design system, one file
  js/main.js                    nav border, scroll reveal, FAQ behaviour
  assets/                       icon, social card, screenshots
  _headers _redirects           Cloudflare Pages configuration
  robots.txt sitemap.xml llms.txt
```

Dark-only by design, so there is no second palette to keep in sync. Every colour
is a token at the top of `styles.css`.

## Local preview

Paths are absolute (`/css/…`), so opening the files over `file://` will not
resolve them. Use a server:

```sh
cd web && python3 -m http.server 8080
```

## Deployment

Cloudflare Pages builds from this repo with **no build command** and the build
output directory set to `web`.

**Leave build watch paths unset.** There is no build step, so a deploy costs
seconds and skipping one saves nothing worth having. A watch path is an
optimisation that fails silently in the worst possible way: commits land, nothing
redeploys, and the live site quietly serves an old build with no error anywhere.
That has already happened here once — the site served the first commit for six
merges. If you do set one, note that a single `*` does not cross `/` in a glob,
so `web/*` misses `web/css/styles.css`; use `web/**`.

`_headers` and `_redirects` are read from the build output directory, which is
why they live at the top of `web/`. They have no effect when previewing locally.

Pages serves HTML **extensionless** and permanently redirects `/foo.html` to
`/foo`. Link to `/support`, not `/support.html`, and never add a redirect pointing
the other way — `/support -> /support.html` loops against that canonicalisation
forever and silently removes the page from the internet.

The `Content-Security-Policy` in `_headers` allows no inline styles or scripts.
Keep CSS in `styles.css` and JavaScript in `main.js` — an inline `style`
attribute is silently dropped in production while looking fine locally.

## Two rules for this repo

**Keep images small, and prefer JPEG.** This repo is also a Swift package, and
SwiftPM clones it in full — every ref, all history — to resolve a dependency. So
anything committed here is downloaded by everyone who depends on the package,
permanently, including files later replaced. Re-encode screenshots before adding
them:

```sh
sips -s format jpeg -s formatOptions 90 shot.png --out shot.jpg
```

**Tag application releases with a prefix, such as `app-v1.0.0`.** SwiftPM reads
git tags as package versions, but only those that parse as semantic versions with
an optional leading `v`. A release tagged `1.0.0` would appear to every consumer
as a catalogue version, and would eventually collide with a real one. A prefixed
tag is ignored, which keeps the two sets of tags independent.

## Licence

The MIT licence in this repository covers the catalogue sources. It does not
extend to the Easy Sweep application, which is distributed under its own terms —
see [terms](https://easysweep.app/terms).
