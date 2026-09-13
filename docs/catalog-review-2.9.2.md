# Catalog 2.9.2 path review

This release adds 37 entries and extends the code-cache selections of ten
existing browsers. The catalog now contains 205 entries: 106 App Data, 87
Developer, and 12 System. The three categories, schema, and Swift API are
unchanged. Existing IDs retain their meaning. New download stores and web data
require cautious cleaning; generated graphics, thumbnails, and build caches can
regenerate during normal use.

The sources below establish the application-owned roots and the selected cache
leaves. Default locations are conditional on their existence. Custom environment
variables, alternate profiles, and project discovery are outside this release.
No applications or caches were removed to perform this review.

## Developer additions

| Entries | Selected locations | Upstream basis and boundary |
| --- | --- | --- |
| `pyenv-downloads` | `~/.pyenv/cache` | [python-build documentation](https://github.com/pyenv/pyenv/blob/master/plugins/python-build/README.md) defines the default download cache. Installed versions and shims stay outside it. |
| `rbenv-downloads` | `~/.rbenv/cache` | [ruby-build documentation](https://github.com/rbenv/ruby-build/blob/master/README.md) defines this cache when installed as an rbenv plugin. Installed Ruby versions stay excluded. |
| `rubygems-specs`, `rubygems-xdg-cache` | `~/.gem/specs`; `~/.cache/gem/{specs,gems}` | [RubyGems defaults](https://github.com/rubygems/rubygems/blob/master/lib/rubygems/defaults.rb) separates downloaded specifications and global gem archives from credentials and installed gems. The legacy specs root remains supported. |
| `yarn-berry-cache` | `~/.yarn/berry/cache` | [Global folder defaults](https://github.com/yarnpkg/berry/blob/master/packages/yarnpkg-core/sources/folderUtils.ts) and [cache configuration](https://github.com/yarnpkg/berry/blob/master/packages/yarnpkg-core/sources/Configuration.ts) establish this package archive cache. Metadata, configuration, and project caches remain excluded. |
| `zig-cache` | `~/.cache/zig` | [Zig's cache resolver](https://github.com/ziglang/zig/blob/master/src/introspect.zig) establishes the global build cache, including the non-Windows default. Project-local `.zig-cache` discovery is separate. |
| `hex-packages`, `hex-xdg-packages` | `~/.hex/packages`; `~/.cache/hex/packages` | [Hex configuration](https://github.com/hexpm/hex/blob/main/lib/hex/config.ex), [state defaults](https://github.com/hexpm/hex/blob/main/lib/hex/state.ex), and [package download code](https://github.com/hexpm/hex/blob/main/lib/hex/scm.ex) establish the normal and `MIX_XDG` locations. `hex.config` and repository configuration are excluded. |
| `opam-downloads` | `~/.opam/download-cache` | [opam's cache documentation](https://opam.ocaml.org/blog/opam-2-1-5-local-cache/) and [clean command](https://opam.ocaml.org/doc/man/opam-clean.html) describe downloaded source archives. Switches, installed compilers, and repository state are excluded. |
| `puppeteer-browsers` | `~/.cache/puppeteer` | [Puppeteer configuration](https://pptr.dev/api/puppeteer.configuration) documents downloaded browsers. Cautious: browser installation must run again before automation can use deleted builds. |
| `sublime-text-cache` | `~/Library/Caches/Sublime Text` | [Sublime Text's reset documentation](https://www.sublimetext.com/docs/revert.html) explicitly separates the macOS cache from Application Support, where sessions and settings remain. |
| `npm-prebuilds` | `~/.npm/_prebuilds` | [prebuild-install utilities](https://github.com/prebuild/prebuild-install/blob/master/util.js) store downloaded native binary archives below npm's cache. Installed modules remain excluded. |
| `npm-logs` | `~/.npm/_logs` | [npm configuration definitions](https://github.com/npm/cli/blob/latest/workspaces/config/lib/definitions/definitions.js) define the default logs directory. Old diagnostic history is lost; new runs create new logs. |
| `vscode-logs` | `~/Library/Application Support/Code/logs` | [VS Code environment service](https://github.com/microsoft/vscode/blob/main/src/vs/platform/environment/common/environmentService.ts) defines timestamped logs under user data. Local History, workspace storage, extensions, settings, and backups remain excluded. |
| `kubectl-cache` | `~/.kube/cache/{http,discovery}` | [Kubernetes client configuration](https://github.com/kubernetes/cli-runtime/blob/master/pkg/genericclioptions/config_flags.go) defines these HTTP and API-discovery caches. The kubeconfig and credential plugins are outside the selections. |

## App Data additions

| Applications | Selection | Upstream basis and boundary |
| --- | --- | --- |
| Chrome, Edge, Brave, Arc, Vivaldi, Opera, Opera GX, Chromium, Yandex, Chrome Canary | Profile `Code Cache`; root `ShaderCache`, `GrShaderCache`, `GraphiteDawnCache` | [Chromium storage partitions](https://github.com/chromium/chromium/blob/main/content/browser/storage_partition_impl.cc) identify generated code caches. [Chromium's browser client](https://github.com/chromium/chromium/blob/main/chrome/browser/chrome_content_browser_client.cc) identifies the three graphics caches. This applies those Chromium leaf names to the already reviewed product roots; each exists only where that browser uses it. Root-level Code Cache is also supported for Opera's profile layout. Profile databases, cookies, passwords, sessions, and service-worker scripts remain excluded. |
| Firefox | `~/Library/Application Support/Firefox/Profiles/*/cache2` | [Firefox cache documentation](https://firefox-source-docs.mozilla.org/networking/cache2/doc.html) describes the cache directory and its entries and index files. This covers profiles whose cache lives alongside profile data. Bookmarks, logins, keys, and session recovery remain excluded. |
| IINA | `~/Library/Caches/com.colliderli.iina/thumb_cache` | [Directory definitions](https://github.com/iina/iina/blob/develop/iina/Utility.swift), [leaf names](https://github.com/iina/iina/blob/develop/iina/AppData.swift), and [thumbnail cache implementation](https://github.com/iina/iina/blob/develop/iina/ThumbnailCache.swift) identify regenerable preview images. The neighboring screenshot cache is deliberately excluded. |
| VLC | `~/Library/Caches/org.videolan.vlc` | [VLC's Darwin directory resolver](https://github.com/videolan/vlc/blob/master/src/darwin/dirs.m) separates its cache, preferences, and application data directories. Playlists and media in Application Support are excluded. |
| Epic Games Launcher | `~/Library/Caches/com.epicgames.EpicGamesLauncher/webcache` | [Epic's macOS cache-clearing instructions](https://www.epicgames.com/help/en-US/c-Category_EpicAccounts/c-TechnicalSupport_GeneralSupport/a000086158) select exactly this folder. Game installations and manifests are excluded. |
| Obsidian | `Cache`, `Code Cache`, `GPUCache`, `GrShaderCache` below `~/Library/Application Support/obsidian` | [Obsidian's storage documentation](https://help.obsidian.md/Files+and+folders/How+Obsidian+stores+data) establishes the root and explicitly describes IndexedDB's sync state. Combined with the Chromium cache definitions above, the selection is limited to named rendering caches. This is an inference from the documented root and underlying engine's cache names, not a full Obsidian reset. IndexedDB, local storage, vaults, and settings are excluded. |
| Figma | Named rendering caches at the Application Support root and below `DesktopProfile` | [Figma's reset instructions](https://help.figma.com/hc/en-us/articles/22380853110551-Clear-the-Figma-desktop-app-cache) establish the macOS application-data root. The catalog intentionally selects only Chromium cache leaves where present; their narrower meaning follows the engine sources above. It does not implement the documented whole-app reset. Offline edit databases, settings, local storage, and worker scripts remain excluded. |
| Microsoft Word, Excel, PowerPoint, Outlook | Each app's container `Data/Library/Caches` | [Microsoft's macOS cache instructions](https://learn.microsoft.com/en-us/office/dev/add-ins/testing/clear-cache) explicitly list these fallback cache directories. The Wef and Documents stores, Office profiles, and the whole OsfWebHost container are excluded. |
| Microsoft Office service | The two documented `com.microsoft.Office365ServiceV2` cache leaves | [Microsoft's cache instructions](https://learn.microsoft.com/en-us/office/dev/add-ins/testing/clear-cache) list both the `Data/Caches` and `Data/Library/Caches` locations. Other service data remains excluded. |

## Deferred locations

These exclusions are specific to this static catalog release. An unverified
location is not a claim that the application has no removable cache.

| Family | Why it is not added |
| --- | --- |
| Ruff, mypy, pytest, Vite, Webpack, Parcel, ESLint, Prettier, Turbo, project-local Zig | The relevant defaults are project-local or configurable. Adding guessed home-directory locations would not discover projects. [Ruff settings](https://docs.astral.sh/ruff/settings/#cache-dir), [mypy cache options](https://mypy.readthedocs.io/en/stable/command_line.html#cmdoption-mypy-cache-dir), and [pytest configuration](https://docs.pytest.org/en/stable/reference/customize.html) illustrate the distinction. |
| pre-commit | Its cache also holds patches preserving temporarily stashed changes. Clearing the whole root needs coordination with the owning process; deleting environments alone leaves the store database inconsistent. [Temporary patch storage](https://github.com/pre-commit/pre-commit/blob/main/pre_commit/staged_files_only.py) and [store cleanup](https://github.com/pre-commit/pre-commit/blob/main/pre_commit/commands/clean.py). |
| Corepack and installed CLI versions | These contain runnable package managers or active binaries. Version selection and tool-aware cleanup need implementation beyond static paths. [Corepack documentation](https://github.com/nodejs/corepack/blob/main/README.md). |
| PyInstaller, Zed temporary storage, CPAN build trees, Bazel outputs, Vagrant staging | Naming these roots does not establish that every file can be removed without active-job coordination or removing locally created output. This release does not add broad build or temporary roots. |
| Ruby installation archives, Bundler, Prisma, alternate Node caches | Default locations and direct-removal semantics were not established sufficiently for additional entries. No installed gems, credentials, or toolchains are selected. |
| Additional editor, AI, and browser variants | CodeBuddy, Qoder, Antigravity, Claude Desktop, ChatGPT, LM Studio rendering caches, Comet, Helium, alternate QQ roots, and alternate bundle-ID caches need verified product roots and contents. Existing named entries remain available. |
| Chrome component archives, optimization stores, and completed Crashpad reports | Component lifecycle, retained model state, and pending-versus-completed reports require more than an unqualified directory name. Only verified code and graphics caches are added here. |
| Steam, Battle.net, GOG, Minecraft, PCSX2, other media and creative applications | Game data, downloaded depots, project media, scratch files, and cache-like databases are not interchangeable. Additional leaves need application-specific source evidence and, where applicable, project or process guards. |
| Notion, Logseq, Bear, Evernote, Alfred, CleanShot, NetNewsWire, MindNode | Broad application-data resets can remove local documents or settings. No additional narrow default cache paths were verified for this release. |
| Box, Baidu, Aliyun, UTM, VMware, Parallels | Offline files, synchronization databases, virtual disks, and snapshots are excluded. Temporary or cache-like names alone are insufficient. |
| System Quick Look, icon services, photo analysis, Messages previews, Apple-wide container caches | Paths may be service-managed, outside the supported user roots, or mixed with application state. No new broad system cache or temporary-directory sweep is introduced. |

## Validation

The package checks JSON decoding, IDs, supported locales, concise descriptions,
root permissions, patterns, risk declarations, symbols, and declared overlap.
Filesystem fixtures additionally resolve the complete catalog against realistic
cache and protected-data paths. Every new fixture must be selected exactly once
by its expected entry, and credentials, unsaved work, screenshots,
profiles, game saves, virtual disks, and neighboring unknown stores must remain
unselected. The browser fixtures cover two profiles and all ten extended roots.
Download and web-data entries are checked against accidental automatic cleaning.

These tests validate selection behavior. They do not replace the upstream review
of what a directory contains, nor test removal from running third-party apps.
