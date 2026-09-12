# Catalog 2.8 review

This release was reviewed against all seven probe files in
[macos-sysdata](https://github.com/Jarvis322/macos-sysdata/tree/ef4ac03b760babe07ee51ba660021e273ac3acbd/Sources/SysDataMenu/Probes).
That repository was used to identify coverage gaps. Definitions, copy, grouping,
and the consuming app's cleanup changes were written independently. Its current
source is proprietary; no implementation was imported.

The result is 171 cleanup entries: 87 App Data entries beneath 62 application
headings, 72 Developer entries, and 12 System entries. Application headings are
inside `appData.json`, with short localized names on the children. Parent
headings are presentation, never a new filesystem deletion scope.

## Added locations and evidence

| Entry | Scope and consequence | Upstream evidence |
|---|---|---|
| `cypress-binaries` | `~/Library/Caches/Cypress`, individual installed versions. Cautious: tests need `cypress install` after removal. | [Cypress binary/cache locations](https://docs.cypress.io/app/references/advanced-installation), [cache commands and reinstall requirement](https://docs.cypress.io/app/references/command-line) |
| `uv-xdg-cache` | `~/.cache/uv`, separately from the existing Library location. Consumer must use uv's command and locks, with the exact measured cache directory. | [uv cache location, safety and clearing](https://docs.astral.sh/uv/concepts/cache/) |
| `xcode-preview-devices` | `~/Library/Developer/Xcode/UserData/Previews/Simulator Devices`. Destructive: installed apps and preview data are lost. Direct builds use the existing simulator-device-set cleaner; sandboxed builds use the existing guarded device-set removal strategy. | [Apple engineer on resetting preview device data](https://developer.apple.com/forums/thread/808442), [preview device-set paths in diagnostics](https://developer.apple.com/forums/tags/xcode-previews?page=6) |
| `huggingface-hub-cache` | Only `~/.cache/huggingface/hub`. Cautious: downloaded Hub repositories must be fetched again. The parent contains authentication tokens and is never a cleanup target. | [Hub environment variables](https://huggingface.co/docs/huggingface_hub/en/package_reference/environment_variables), [Hub cache management](https://huggingface.co/docs/huggingface_hub/en/guides/manage-cache) |
| `pytorch-checkpoints` | Only `~/.cache/torch/hub/checkpoints`. Cautious: downloaded weights must be fetched again. The remainder of `torch/hub`, including source repositories, is excluded. | [PyTorch Hub implementation: default Hub home and checkpoint downloads](https://github.com/pytorch/pytorch/blob/main/torch/hub.py) |
| `chrome-ai-model` | Only Chrome's `OptGuideOnDeviceModel` directory. Cautious: on-device AI may need a large download before working again. | [Chromium's model component installer](https://chromium.googlesource.com/chromium/src/+/HEAD/chrome/browser/component_updater/optimization_guide_on_device_model_installer.cc) |
| `spotify-offline-storage` | Only `Spotify/PersistentCache/Storage`, not the whole PersistentCache folder. Cautious: this can hold offline audio, not just disposable streaming buffers. | [Spotify moderators identify Storage and its offline cache](https://community.spotify.com/t5/Desktop-Mac/Local-Files-not-finding-many-files/m-p/5172177/highlight/true), [Spotify storage distinctions](https://support.spotify.com/us/article/storage-information/) |
| `safari-container-cache`, `teams-container-cache` | Only each known app container's `Data/Library/Caches`. Safe classification follows Apple's cache-directory contract; neither app's Documents or Application Support root is selected. Container locations remain subject to the consuming build's access limits. | [Apple cache-directory and container semantics](https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/FileSystemOverview/FileSystemOverview.html), [Microsoft's Teams container/cache reset documentation](https://learn.microsoft.com/en-us/troubleshoot/microsoftteams/teams-administration/clear-teams-cache) |
| `vscode-web-cache` | Only `Code/Cache`, `Code Cache`, `GPUCache`, and `GrShaderCache`. Cautious, consistent with the named messaging app web caches. Editor settings, workspace storage and extensions are excluded. | [VS Code's macOS application-data root](https://code.visualstudio.com/docs/setup/uninstall), [Electron session-data/cache layout](https://www.electronjs.org/docs/latest/api/app#appgetpathname) |

The Safari/Teams subdirectory choice is an inference from the documented
container layout and cache semantics. Microsoft's full reset instructions are
broader than these entries and are not reproduced as deletion targets.

## Generic entries retired

`xdg-cache` no longer selects arbitrary children of `~/.cache`. Named uv,
Hugging Face and PyTorch locations replace the verified portions. Hugging Face's
`token` and `stored_tokens`, unknown cache owners, processed datasets and Xet
upload staging are outside the declared cleanup paths.

`electron-http-caches` and `electron-code-caches` no longer search every app's
Application Support directory. Slack, Discord, Signal, Element, Beeper and
Mattermost retain their existing IDs, adding the four explicitly named cache
directories to their existing web-data targets. VS Code receives its own
entry. Electron documents that session data also includes cookies and local
storage, so those directories are deliberately absent. Existing cautious risks
remain cautious.

## Remaining probe families

| Reviewed family | Decision |
|---|---|
| Package download caches, browser caches, Xcode builds/archives, existing simulator sets, AI model/session stores | Substantial existing coverage. No duplicate entries for the same bytes. |
| iPhone/iPad backups and device firmware | Already represented in System, with destructive backups separate from downloadable firmware. |
| User logs and CoreSimulator logs | Existing `user-logs` covers them. No overlapping diagnostic-report entry. |
| visionOS device support | Candidate pending stronger primary evidence for the exact cache path. Do not infer a deletion path from another platform's spelling alone. |
| Simulator runtimes and per-device scratch space | Need runtime/device metadata and tool-coordinated cleanup. Per-device caches would also overlap the existing whole-device target. |
| Android SDK versions and AVDs | Require SDK/AVD-aware removal and paired metadata handling. Installed SDKs and emulator disks are not download caches. |
| Docker reclaimable storage | Needs a dedicated Docker command adapter and actual reclaimable-space measurement. A VM disk's allocated size is not a prune estimate. |
| Final Cut project renders and project build folders | Need user-chosen project roots and project-specific handling. Native cleanup is preferable for media libraries. |
| Parallels, UTM, VMware, OrbStack, Lima/Colima and Claude VM bundles | Whole VM storage can contain unique work. No generic cache entry for VM disks or whole app state. |
| Mail attachment downloads | Can include locally edited attachments; not added as an automatic cache cleanup. |
| Broad Adobe, Steam, Epic, Zoom and app-container data | Includes installed content, settings or user data. Keep only independently verified, narrow existing targets. |
| Photos and Quick Look | Candidate cache locations need stronger owner-specific evidence or a native cache reset before adding a target. |
| Time Machine snapshots, shared folders, other accounts, system logs/caches, toolchain installations, Spotlight, swap, cryptexes, cloud data and service containers | These require separate system or uninstall workflows, or must remain OS-managed. Not static user-cache entries. |
| Large-folder and unknown-dotfolder discovery | Useful for storage inspection, but size and a hidden name do not establish cleanup eligibility. |

## Validation boundaries

Package tests check nested decoding, group identity, translations, current
category aliases, risk declarations, and bounded resolution against fixtures.
The fixtures include credentials, unknown applications and local data that must
never resolve as cleanup paths. Tests do not delete real application data.
The consuming app additionally tests grouped selection, preview-set routing,
and uv failures without invoking a real cache-cleaning command.
