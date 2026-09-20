# Catalog 2.9.4 review

This release adds 26 entries for applications and developer tools the catalog
did not yet cover. The catalog grows from 205 to 231 entries: 21 under 17 new
applications in App Data and five in Developer. No category, API, or cleanup
engine changes are required.

A commonly repeated path is not evidence. Five first-pass candidates named
folders that no version of the app creates, so every path below is confirmed
against an upstream source, and a candidate with no such source was left out.

## Evidence rule for application caches

`~/Library/Caches/<bundle-id>` is the location Apple's [File System Programming
Guide](https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/MacOSXDirectories/MacOSXDirectories.html)
assigns to data an app "can re-create" and that the system may purge. A sandboxed
app receives the same folder inside its container. What has to be verified for
such an entry is therefore the identifier, and whether the app is sandboxed. Both
are taken from the uninstall (`zap`) stanza of the app's Homebrew cask, which
lists the folders the app is known to create.

| Entry | Path | Source |
|---|---|---|
| `claude-desktop-cache` | `~/Library/Caches/com.anthropic.claudefordesktop` | [cask `claude`](https://formulae.brew.sh/cask/claude) |
| `antigravity-cache` | `~/Library/Caches/com.google.antigravity` | [cask `antigravity`](https://formulae.brew.sh/cask/antigravity) |
| `zed-cache` | `~/Library/Caches/Zed` | [cask `zed`](https://formulae.brew.sh/cask/zed) |
| `ghostty-cache` | `~/Library/Caches/com.mitchellh.ghostty` | [cask `ghostty`](https://formulae.brew.sh/cask/ghostty) |
| `notion-cache` | `~/Library/Caches/notion.id` | [cask `notion`](https://formulae.brew.sh/cask/notion) |
| `postman-cache` | `~/Library/Caches/com.postmanlabs.mac` | [cask `postman`](https://formulae.brew.sh/cask/postman) |
| `insomnia-cache` | `~/Library/Caches/com.insomnia.app` | [cask `insomnia`](https://formulae.brew.sh/cask/insomnia) |
| `tableplus-cache` | `~/Library/Caches/com.tinyapp.TablePlus` | [cask `tableplus`](https://formulae.brew.sh/cask/tableplus) |
| `proxyman-cache` | `~/Library/Caches/com.proxyman.NSProxy` | [cask `proxyman`](https://formulae.brew.sh/cask/proxyman) |
| `mongodb-compass-cache` | `~/Library/Caches/MongoDB Compass` | [cask `mongodb-compass`](https://formulae.brew.sh/cask/mongodb-compass) |
| `github-desktop-cache` | `~/Library/Caches/com.github.GitHubClient` | [cask `github`](https://formulae.brew.sh/cask/github) |
| `sequel-ace-cache` | `~/Library/Containers/com.sequel-ace.sequel-ace/Data/Library/Caches` | [cask `sequel-ace`](https://formulae.brew.sh/cask/sequel-ace) — sandboxed, container only |
| `helium-cache` | `~/Library/Caches/net.imput.helium` | [cask `helium-browser`](https://formulae.brew.sh/cask/helium-browser) |
| `comet-cache` | `~/Library/Caches/Comet` | [cask `comet`](https://formulae.brew.sh/cask/comet) |
| `battle-net-cache` | `~/Library/Caches/net.battle.bootstrapper` | [cask `battle-net`](https://formulae.brew.sh/cask/battle-net) |
| `minecraft-launcher-cache` | `~/Library/Caches/com.mojang.minecraftlauncher` | [cask `minecraft`](https://formulae.brew.sh/cask/minecraft) |
| `utm-cache` | `~/Library/Containers/com.utmapp.UTM/Data/Library/Caches` | [cask `utm`](https://formulae.brew.sh/cask/utm) — sandboxed, container only |

All are `safe`. Each names one folder whose whole purpose is regenerable data,
which is the narrow, auditable shape `safe` requires.

## Chromium and Electron profile caches

`claude-desktop-web-cache`, `antigravity-web-cache`, `helium-site-cache` and
`helium-shader-cache` select named Chromium cache directories inside an
application support folder the cask confirms (`Application Support/Claude`,
`Application Support/Antigravity`, `Application Support/net.imput.helium`).
The directory names — `Cache`, `Code Cache`, `GPUCache`, `DawnGraphiteCache`,
`DawnWebGPUCache`, `ShaderCache`, `GrShaderCache`, `GraphiteDawnCache`,
`Service Worker/CacheStorage` — are the ones the catalog already selects for
Chrome, Brave, Arc, Discord, Figma and Obsidian, and carry the same names and
risks: web and site data `cautious`, shader caches `safe`.

Nothing else in those folders is selected. Cookies, `Local Storage`,
`IndexedDB`, `Session Storage`, `Preferences`, `Local State` and
`Service Worker/ScriptCache` are siblings of the named directories and no
pattern reaches them; `chromiumScriptStoresStayOutsideCleanup` covers the new
Helium entry automatically. Claude's `claude_desktop_config.json` and its MCP
configuration sit at the root of `Application Support/Claude` and are likewise
outside every named subfolder.

## Developer entries

| Entry | Path | Risk | Source |
|---|---|---|---|
| `bazelisk-downloads` | `~/Library/Caches/bazelisk` | cautious | [Bazelisk README](https://github.com/bazelbuild/bazelisk#readme): downloaded Bazel binaries are stored in a `bazelisk` directory inside the [user cache directory](https://pkg.go.dev/os#UserCacheDir), which is `~/Library/Caches` on macOS. Cautious because each Bazel version is downloaded again. |
| `opencode-cache` | `~/.cache/opencode` | safe | [OpenCode troubleshooting](https://opencode.ai/docs/troubleshooting/) directs users to delete `~/.cache/opencode`; provider packages reinstall on next start. |
| `cpan-build` | `~/.cpan/build` | safe | [CPAN.pm `build_dir`](https://metacpan.org/pod/CPAN#Config-Variables): the directory where modules are unpacked and built; installed modules live elsewhere. |
| `oh-my-zsh-cache` | `~/.oh-my-zsh/cache` | safe | [`oh-my-zsh.sh`](https://github.com/ohmyzsh/ohmyzsh/blob/master/oh-my-zsh.sh) sets `ZSH_CACHE_DIR="$ZSH/cache"`; plugins regenerate completions there. |
| `aws-cli-cache` | `~/.aws/cli/cache` | cautious | [AWS CLI role configuration](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-role.html): temporary role credentials are cached there and may be deleted to force a refresh. Cautious because the next command may prompt for MFA again. `~/.aws/credentials`, `~/.aws/config` and `~/.aws/sso/cache` are not selected. |

## Candidates not added

`~/.cache/node/corepack` and `~/.cache/pre-commit` were considered and are
already fixtures in `ProtectedDataTests`: the first holds the package manager
binaries a project runs, the second holds in-progress patch files. Both stay
out.

These had no upstream source and were dropped rather than shipped on trust:
ChatGPT (`com.openai.chat` — the current cask names `com.openai.codex`, which
the catalog already covers), Qoder, Ora, Warp, Charles, Blender, Final Cut Pro,
DaVinci Resolve including `~/Movies/CacheClip`, Steam's `appcache` /
`depotcache` / `htmlcache` / `shadercache`, Battle.net's application support
cache, Minecraft's `webcache`, Zed's bundled npm cache, Podcasts'
`StreamedMedia`, Docker Buildx, Prisma, Bundler, RubyGems' per-version cache,
Expo's template caches, Vagrant's `tmp`, and the Azure and Google Cloud CLI log
folders. Any of them can return with a citation.

`~/.cache/bazel` is Bazel's Linux output root and is never created on macOS,
so it is not an entry.

## Localization

Every new entry uses a name and description the catalog already carries, so
all 16 localizations are copied from existing entries rather than newly
translated. Application names are brand names and are identical in every
language, as they are for the existing applications.

## Limits

None of these applications was installed on the machine where the entries were
written; the only new path present there was Ghostty's cache. Path existence on
a real install is taken from the cask maintainers, not observed.
