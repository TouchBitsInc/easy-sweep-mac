# Catalog 2.12.0 review

This release adds 122 application caches. The catalog grows from 231 to
353 entries.

## How they were chosen

The candidates are the most installed Mac apps, by Homebrew's public 365-day
[cask install counts](https://formulae.brew.sh/analytics/cask-install/365d/),
top 400. For each one, the cask's uninstall (`zap`) list names the folders the
app creates. A folder was added when it is a direct child of
`~/Library/Caches` that no existing entry already names.

Left out on purpose:

- **Updaters, helpers and crash reporters** (`Keystone`, `*.helper`,
  `*updater*`, `crashreporter`). They stage installs rather than cache content.
- **Security and network tools** (password managers, VPNs, firewalls, file
  system extensions). Clearing their state is not worth the risk.
- **Sync clients** (Dropbox, OneDrive, Google Drive, Nextcloud, Syncthing). A
  cache there can hold files not yet uploaded.
- **Other disk cleaners and uninstallers.**
- **Versioned folders** such as `PyCharm2025.2`, and apps the catalog already
  covers under a different heading.
- **Second folders.** One folder per app, so a heading doesn't list "Cache"
  several times.

## Risk

Every new entry is `cautious`, never `safe`. Apple's [File System Programming
Guide](https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/MacOSXDirectories/MacOSXDirectories.html)
says this folder holds data an app can re-create, and the cask confirms the
folder belongs to the app. Neither shows what each app actually keeps there,
so none of these may be cleaned without the user choosing them. An entry can
move to `safe` later with its own source.

## Entries

| Entry | App | Path | Source |
|---|---|---|---|
| `adobe-acrobat-reader-cache` | Adobe Acrobat Reader | `~/Library/Caches/com.adobe.Reader` | [cask `adobe-acrobat-reader`](https://formulae.brew.sh/cask/adobe-acrobat-reader) |
| `affinity-cache` | Affinity | `~/Library/Caches/com.canva.affinity` | [cask `affinity`](https://formulae.brew.sh/cask/affinity) |
| `aldente-cache` | AlDente | `~/Library/Caches/com.apphousekitchen.aldente-pro` | [cask `aldente`](https://formulae.brew.sh/cask/aldente) |
| `alfred-cache` | Alfred | `~/Library/Caches/com.runningwithcrayons.Alfred` | [cask `alfred`](https://formulae.brew.sh/cask/alfred) |
| `alt-tab-cache` | AltTab | `~/Library/Caches/com.lwouis.alt-tab-macos` | [cask `alt-tab`](https://formulae.brew.sh/cask/alt-tab) |
| `amethyst-cache` | Amethyst | `~/Library/Caches/com.amethyst.Amethyst` | [cask `amethyst`](https://formulae.brew.sh/cask/amethyst) |
| `anki-cache` | Anki | `~/Library/Caches/Anki` | [cask `anki`](https://formulae.brew.sh/cask/anki) |
| `antigravity-ide-cache` | Antigravity IDE | `~/Library/Caches/com.google.antigravity-ide` | [cask `antigravity-ide`](https://formulae.brew.sh/cask/antigravity-ide) |
| `arc-app-cache` | Arc | `~/Library/Caches/Arc` | [cask `arc`](https://formulae.brew.sh/cask/arc) |
| `audacity-cache` | Audacity | `~/Library/Caches/Audacity` | [cask `audacity`](https://formulae.brew.sh/cask/audacity) |
| `bambu-studio-cache` | Bambu Studio | `~/Library/Caches/com.bambulab.bambu-studio` | [cask `bambu-studio`](https://formulae.brew.sh/cask/bambu-studio) |
| `bartender-cache` | Bartender | `~/Library/Caches/com.surteesstudios.Bartender` | [cask `bartender`](https://formulae.brew.sh/cask/bartender) |
| `battery-cache` | Battery | `~/Library/Caches/co.palokaj.battery` | [cask `battery`](https://formulae.brew.sh/cask/battery) |
| `bbedit-cache` | BBEdit | `~/Library/Caches/com.barebones.bbedit` | [cask `bbedit`](https://formulae.brew.sh/cask/bbedit) |
| `beekeeper-studio-cache` | Beekeeper Studio | `~/Library/Caches/io.beekeeperstudio.desktop` | [cask `beekeeper-studio`](https://formulae.brew.sh/cask/beekeeper-studio) |
| `betterdisplay-cache` | BetterDisplay | `~/Library/Caches/pro.betterdisplay.BetterDisplay` | [cask `betterdisplay`](https://formulae.brew.sh/cask/betterdisplay) |
| `bettertouchtool-cache` | BetterTouchTool | `~/Library/Caches/com.hegenberg.BetterTouchTool` | [cask `bettertouchtool`](https://formulae.brew.sh/cask/bettertouchtool) |
| `brave-app-cache` | Brave | `~/Library/Caches/com.brave.Browser` | [cask `brave-browser`](https://formulae.brew.sh/cask/brave-browser) |
| `caffeine-cache` | Caffeine | `~/Library/Caches/com.intelliscapesolutions.caffeine` | [cask `caffeine`](https://formulae.brew.sh/cask/caffeine) |
| `calibre-cache` | calibre | `~/Library/Caches/calibre` | [cask `calibre`](https://formulae.brew.sh/cask/calibre) |
| `cc-switch-cache` | CC Switch | `~/Library/Caches/com.ccswitch.desktop` | [cask `cc-switch`](https://formulae.brew.sh/cask/cc-switch) |
| `chatgpt-atlas-cache` | ChatGPT Atlas | `~/Library/Caches/com.openai.atlas` | [cask `chatgpt-atlas`](https://formulae.brew.sh/cask/chatgpt-atlas) |
| `chrome-app-cache` | Google Chrome | `~/Library/Caches/com.google.Chrome` | [cask `google-chrome`](https://formulae.brew.sh/cask/google-chrome) |
| `cleanshot-cache` | CleanShot | `~/Library/Caches/pl.maketheweb.cleanshotx` | [cask `cleanshot`](https://formulae.brew.sh/cask/cleanshot) |
| `clipy-cache` | Clipy | `~/Library/Caches/com.clipy-app.Clipy` | [cask `clipy`](https://formulae.brew.sh/cask/clipy) |
| `cmux-cache` | cmux | `~/Library/Caches/cmux` | [cask `cmux`](https://formulae.brew.sh/cask/cmux) |
| `codexbar-cache` | CodexBar | `~/Library/Caches/CodexBar` | [cask `codexbar`](https://formulae.brew.sh/cask/codexbar) |
| `coteditor-cache` | CotEditor | `~/Library/Caches/com.coteditor.CotEditor` | [cask `coteditor`](https://formulae.brew.sh/cask/coteditor) |
| `crossover-cache` | CrossOver | `~/Library/Caches/com.codeweavers.CrossOver` | [cask `crossover`](https://formulae.brew.sh/cask/crossover) |
| `cyberduck-cache` | Cyberduck | `~/Library/Caches/ch.sudo.cyberduck` | [cask `cyberduck`](https://formulae.brew.sh/cask/cyberduck) |
| `dbeaver-cache` | DBeaver | `~/Library/Caches/org.jkiss.dbeaver.core.product` | [cask `dbeaver-community`](https://formulae.brew.sh/cask/dbeaver-community) |
| `dia-app-cache` | Dia | `~/Library/Caches/company.thebrowser.dia` | [cask `thebrowsercompany-dia`](https://formulae.brew.sh/cask/thebrowsercompany-dia) |
| `discord-cache` | Discord | `~/Library/Caches/com.hnc.Discord` | [cask `discord`](https://formulae.brew.sh/cask/discord) |
| `dockdoor-cache` | DockDoor | `~/Library/Caches/com.ethanbills.DockDoor` | [cask `dockdoor`](https://formulae.brew.sh/cask/dockdoor) |
| `docker-desktop-cache` | Docker Desktop | `~/Library/Caches/com.docker.docker` | [cask `docker-desktop`](https://formulae.brew.sh/cask/docker-desktop) |
| `drawio-cache` | draw.io | `~/Library/Caches/com.jgraph.drawio.desktop` | [cask `drawio`](https://formulae.brew.sh/cask/drawio) |
| `duckduckgo-app-cache` | DuckDuckGo | `~/Library/Caches/com.duckduckgo.macos.browser` | [cask `duckduckgo`](https://formulae.brew.sh/cask/duckduckgo) |
| `easydict-cache` | Easydict | `~/Library/Caches/com.izual.Easydict` | [cask `easydict`](https://formulae.brew.sh/cask/easydict) |
| `edge-app-cache` | Microsoft Edge | `~/Library/Caches/com.microsoft.edgemac` | [cask `microsoft-edge`](https://formulae.brew.sh/cask/microsoft-edge) |
| `emacs-cache` | Emacs | `~/Library/Caches/org.gnu.Emacs` | [cask `emacs-app`](https://formulae.brew.sh/cask/emacs-app) |
| `espanso-cache` | Espanso | `~/Library/Caches/espanso` | [cask `espanso`](https://formulae.brew.sh/cask/espanso) |
| `figma-cache` | Figma | `~/Library/Caches/com.figma.Desktop` | [cask `figma`](https://formulae.brew.sh/cask/figma) |
| `firefox-app-cache` | Firefox | `~/Library/Caches/org.mozilla.firefox` | [cask `firefox`](https://formulae.brew.sh/cask/firefox) |
| `flameshot-cache` | Flameshot | `~/Library/Caches/flameshot` | [cask `flameshot`](https://formulae.brew.sh/cask/flameshot) |
| `fluidvoice-cache` | FluidVoice | `~/Library/Caches/com.FluidApp.app` | [cask `fluidvoice`](https://formulae.brew.sh/cask/fluidvoice) |
| `fork-cache` | Fork | `~/Library/Caches/com.DanPristupov.Fork` | [cask `fork`](https://formulae.brew.sh/cask/fork) |
| `freecad-cache` | FreeCAD | `~/Library/Caches/FreeCAD` | [cask `freecad`](https://formulae.brew.sh/cask/freecad) |
| `gemini-app-cache` | Gemini | `~/Library/Caches/com.google.GeminiMacOS` | [cask `google-gemini`](https://formulae.brew.sh/cask/google-gemini) |
| `godot-cache` | Godot Engine | `~/Library/Caches/Godot` | [cask `godot`](https://formulae.brew.sh/cask/godot) |
| `hammerspoon-cache` | Hammerspoon | `~/Library/Caches/org.hammerspoon.Hammerspoon` | [cask `hammerspoon`](https://formulae.brew.sh/cask/hammerspoon) |
| `handbrake-cache` | HandBrake | `~/Library/Caches/fr.handbrake.HandBrake` | [cask `handbrake-app`](https://formulae.brew.sh/cask/handbrake-app) |
| `handy-cache` | Handy | `~/Library/Caches/com.pais.handy` | [cask `handy`](https://formulae.brew.sh/cask/handy) |
| `ice-cache` | Ice | `~/Library/Caches/com.jordanbaird.Ice` | [cask `jordanbaird-ice`](https://formulae.brew.sh/cask/jordanbaird-ice) |
| `istat-menus-cache` | iStat Menus | `~/Library/Caches/com.bjango.istatmenus` | [cask `istat-menus`](https://formulae.brew.sh/cask/istat-menus) |
| `iterm2-cache` | iTerm2 | `~/Library/Caches/com.googlecode.iterm2` | [cask `iterm2`](https://formulae.brew.sh/cask/iterm2) |
| `keepingyouawake-cache` | KeepingYouAwake | `~/Library/Caches/info.marcel-dierkes.KeepingYouAwake` | [cask `keepingyouawake`](https://formulae.brew.sh/cask/keepingyouawake) |
| `keka-cache` | Keka | `~/Library/Caches/com.aone.keka` | [cask `keka`](https://formulae.brew.sh/cask/keka) |
| `keyclu-cache` | KeyClu | `~/Library/Caches/com.0804Team.KeyClu` | [cask `keyclu`](https://formulae.brew.sh/cask/keyclu) |
| `kiro-cli-cache` | Kiro CLI | `~/Library/Caches/com.amazon.codewhisperer` | [cask `kiro-cli`](https://formulae.brew.sh/cask/kiro-cli) |
| `kitty-cache` | kitty | `~/Library/Caches/kitty` | [cask `kitty`](https://formulae.brew.sh/cask/kitty) |
| `krita-cache` | Krita | `~/Library/Caches/krita` | [cask `krita`](https://formulae.brew.sh/cask/krita) |
| `lark-app-cache` | Lark | `~/Library/Caches/com.electron.lark` | [cask `feishu`](https://formulae.brew.sh/cask/feishu) |
| `lens-cache` | Lens | `~/Library/Caches/Lens` | [cask `lens`](https://formulae.brew.sh/cask/lens) |
| `librewolf-app-cache` | LibreWolf | `~/Library/Caches/LibreWolf Community` | [cask `librewolf`](https://formulae.brew.sh/cask/librewolf) |
| `lmstudio-cache` | LM Studio | `~/Library/Caches/ai.elementlabs.lmstudio` | [cask `lm-studio`](https://formulae.brew.sh/cask/lm-studio) |
| `loop-cache` | Loop | `~/Library/Caches/com.MrKai77.Loop` | [cask `loop`](https://formulae.brew.sh/cask/loop) |
| `lunar-cache` | Lunar | `~/Library/Caches/Lunar` | [cask `lunar`](https://formulae.brew.sh/cask/lunar) |
| `mac-mouse-fix-cache` | Mac Mouse Fix | `~/Library/Caches/com.nuebling.mac-mouse-fix` | [cask `mac-mouse-fix`](https://formulae.brew.sh/cask/mac-mouse-fix) |
| `macdown-cache` | MacDown | `~/Library/Caches/com.uranusjr.macdown` | [cask `macdown`](https://formulae.brew.sh/cask/macdown) |
| `macwhisper-cache` | MacWhisper | `~/Library/Caches/com.goodsnooze.MacWhisper` | [cask `macwhisper`](https://formulae.brew.sh/cask/macwhisper) |
| `marta-cache` | Marta | `~/Library/Caches/org.yanex.marta` | [cask `marta`](https://formulae.brew.sh/cask/marta) |
| `meld-cache` | Meld | `~/Library/Caches/org.gnome.Meld` | [cask `meld`](https://formulae.brew.sh/cask/meld) |
| `microsoft-excel-app-cache` | Microsoft Excel | `~/Library/Caches/com.microsoft.Excel` | [cask `microsoft-excel`](https://formulae.brew.sh/cask/microsoft-excel) |
| `moonlight-cache` | Moonlight | `~/Library/Caches/Moonlight Game Streaming Project` | [cask `moonlight`](https://formulae.brew.sh/cask/moonlight) |
| `mysqlworkbench-cache` | MySQL Workbench | `~/Library/Caches/com.oracle.workbench.MySQLWorkbench` | [cask `mysqlworkbench`](https://formulae.brew.sh/cask/mysqlworkbench) |
| `ollama-cache` | Ollama | `~/Library/Caches/com.electron.ollama` | [cask `ollama-app`](https://formulae.brew.sh/cask/ollama-app) |
| `openclaw-cache` | OpenClaw | `~/Library/Caches/ai.openclaw.mac` | [cask `openclaw`](https://formulae.brew.sh/cask/openclaw) |
| `openlogi-cache` | OpenLogi | `~/Library/Caches/org.openlogi.openlogi` | [cask `openlogi`](https://formulae.brew.sh/cask/openlogi) |
| `openscad-cache` | OpenSCAD | `~/Library/Caches/org.openscad.OpenSCAD` | [cask `openscad`](https://formulae.brew.sh/cask/openscad) |
| `orbstack-cache` | OrbStack | `~/Library/Caches/dev.kdrag0n.MacVirt` | [cask `orbstack`](https://formulae.brew.sh/cask/orbstack) |
| `pgadmin4-cache` | pgAdmin 4 | `~/Library/Caches/pgAdmin 4` | [cask `pgadmin4`](https://formulae.brew.sh/cask/pgadmin4) |
| `postman-app-cache` | Postman | `~/Library/Caches/Postman` | [cask `postman`](https://formulae.brew.sh/cask/postman) |
| `proxyman-app-cache` | Proxyman | `~/Library/Caches/Proxyman` | [cask `proxyman`](https://formulae.brew.sh/cask/proxyman) |
| `qbittorrent-cache` | qBittorrent | `~/Library/Caches/qBittorrent` | [cask `qbittorrent`](https://formulae.brew.sh/cask/qbittorrent) |
| `qgis-cache` | QGIS | `~/Library/Caches/QGIS` | [cask `qgis`](https://formulae.brew.sh/cask/qgis) |
| `rancher-cache` | Rancher Desktop | `~/Library/Caches/rancher-desktop` | [cask `rancher`](https://formulae.brew.sh/cask/rancher) |
| `raspberry-pi-imager-cache` | Raspberry Pi Imager | `~/Library/Caches/Raspberry Pi/Imager` | [cask `raspberry-pi-imager`](https://formulae.brew.sh/cask/raspberry-pi-imager) names the `Raspberry Pi` parent; Qt keeps each app's cache in `<organisation>/<app>`, so only Imager's own folder is taken |
| `raycast-cache` | Raycast | `~/Library/Caches/com.raycast.macos` | [cask `raycast`](https://formulae.brew.sh/cask/raycast) |
| `rectangle-cache` | Rectangle | `~/Library/Caches/com.knollsoft.Rectangle` | [cask `rectangle`](https://formulae.brew.sh/cask/rectangle) |
| `redis-insight-cache` | Redis Insight | `~/Library/Caches/org.RedisLabs.RedisInsight-V3` | [cask `redis-insight`](https://formulae.brew.sh/cask/redis-insight) |
| `scroll-reverser-cache` | Scroll Reverser | `~/Library/Caches/com.pilotmoon.scroll-reverser` | [cask `scroll-reverser`](https://formulae.brew.sh/cask/scroll-reverser) |
| `skim-cache` | Skim | `~/Library/Caches/net.sourceforge.skim-app.skim` | [cask `skim`](https://formulae.brew.sh/cask/skim) |
| `sourcetree-cache` | SourceTree | `~/Library/Caches/com.torusknot.SourceTreeNotMAS` | [cask `sourcetree`](https://formulae.brew.sh/cask/sourcetree) |
| `squirrel-ime-cache` | Squirrel | `~/Library/Caches/com.googlecode.rimeime.inputmethod.Squirrel` | [cask `squirrel-app`](https://formulae.brew.sh/cask/squirrel-app) |
| `stats-cache` | Stats | `~/Library/Caches/eu.exelban.Stats` | [cask `stats`](https://formulae.brew.sh/cask/stats) |
| `stremio-cache` | Stremio | `~/Library/Caches/com.stremio.stremio-shell-macos` | [cask `stremio`](https://formulae.brew.sh/cask/stremio) |
| `supacode-cache` | supacode | `~/Library/Caches/app.supabit.supacode` | [cask `supacode`](https://formulae.brew.sh/cask/supacode) |
| `superwhisper-cache` | Superwhisper | `~/Library/Caches/com.superduper.superwhisper` | [cask `superwhisper`](https://formulae.brew.sh/cask/superwhisper) |
| `swiftbar-cache` | SwiftBar | `~/Library/Caches/com.ameba.SwiftBar` | [cask `swiftbar`](https://formulae.brew.sh/cask/swiftbar) |
| `t3-code-cache` | T3 Code | `~/Library/Caches/com.t3tools.t3code` | [cask `t3-code`](https://formulae.brew.sh/cask/t3-code) |
| `tabby-cache` | Tabby | `~/Library/Caches/org.tabby` | [cask `tabby`](https://formulae.brew.sh/cask/tabby) |
| `teams-app-cache` | Microsoft Teams | `~/Library/Caches/com.microsoft.teams` | [cask `microsoft-teams`](https://formulae.brew.sh/cask/microsoft-teams) |
| `teamviewer-cache` | TeamViewer | `~/Library/Caches/com.teamviewer.TeamViewer` | [cask `teamviewer`](https://formulae.brew.sh/cask/teamviewer) |
| `telegram-app-cache` | Telegram | `~/Library/Caches/ru.keepcoder.Telegram` | [cask `telegram`](https://formulae.brew.sh/cask/telegram) |
| `thaw-cache` | Thaw | `~/Library/Caches/com.stonerl.Thaw` | [cask `thaw`](https://formulae.brew.sh/cask/thaw) |
| `the-unarchiver-cache` | The Unarchiver | `~/Library/Caches/cx.c3.theunarchiver` | [cask `the-unarchiver`](https://formulae.brew.sh/cask/the-unarchiver) |
| `thunderbird-cache` | Thunderbird | `~/Library/Caches/Thunderbird` | [cask `thunderbird`](https://formulae.brew.sh/cask/thunderbird) |
| `transmission-cache` | Transmission | `~/Library/Caches/org.m0k.transmission` | [cask `transmission`](https://formulae.brew.sh/cask/transmission) |
| `typora-cache` | Typora | `~/Library/Caches/abnerworks.Typora` | [cask `typora`](https://formulae.brew.sh/cask/typora) |
| `vscode-insiders-app-cache` | VS Code Insiders | `~/Library/Caches/com.microsoft.VSCodeInsiders` | [cask `visual-studio-code@insiders`](https://formulae.brew.sh/cask/visual-studio-code@insiders) |
| `vivaldi-app-cache` | Vivaldi | `~/Library/Caches/com.vivaldi.Vivaldi` | [cask `vivaldi`](https://formulae.brew.sh/cask/vivaldi) |
| `voiceink-cache` | VoiceInk | `~/Library/Caches/com.prakashjoshipax.VoiceInk` | [cask `voiceink`](https://formulae.brew.sh/cask/voiceink) |
| `vorssaint-cache` | Vorssaint | `~/Library/Caches/com.vorssaint.utils` | [cask `vorssaint`](https://formulae.brew.sh/cask/vorssaint) |
| `vscode-app-cache` | VS Code | `~/Library/Caches/com.microsoft.VSCode` | [cask `visual-studio-code`](https://formulae.brew.sh/cask/visual-studio-code) |
| `vscodium-cache` | VSCodium | `~/Library/Caches/com.vscodium` | [cask `vscodium`](https://formulae.brew.sh/cask/vscodium) |
| `wechat-app-cache` | WeChat | `~/Library/Caches/com.tencent.xinWeChat` | [cask `wechat`](https://formulae.brew.sh/cask/wechat) |
| `whatsapp-app-cache` | WhatsApp | `~/Library/Caches/net.whatsapp.WhatsApp` | [cask `whatsapp`](https://formulae.brew.sh/cask/whatsapp) |
| `wireshark-cache` | Wireshark | `~/Library/Caches/org.wireshark.Wireshark` | [cask `wireshark-app`](https://formulae.brew.sh/cask/wireshark-app) |
| `wispr-flow-cache` | Wispr Flow | `~/Library/Caches/com.electron.wispr-flow` | [cask `wispr-flow`](https://formulae.brew.sh/cask/wispr-flow) |
| `xquartz-cache` | XQuartz | `~/Library/Caches/org.xquartz.X11` | [cask `xquartz`](https://formulae.brew.sh/cask/xquartz) |
| `zed-app-cache` | Zed | `~/Library/Caches/dev.zed.Zed` | [cask `zed`](https://formulae.brew.sh/cask/zed) |
| `zotero-cache` | Zotero | `~/Library/Caches/Zotero` | [cask `zotero`](https://formulae.brew.sh/cask/zotero) |

## Also considered and left out

- `~/Library/Caches/org.R-project.R` is where every R package keeps its cache,
  and renv's global package store lives inside it. Clearing it breaks renv
  projects until `renv::restore()` runs, so it is not an app cache.
- Quarto installs as a command-line tool with no app, so it does not belong
  under App Data.

## Discontinued casks

Homebrew has disabled five of the source casks: `chatgpt-atlas`, `flameshot`,
`macdown`, `openscad` and `qbittorrent`. The apps still exist on Macs that
installed them, and the folders are unchanged, but those links may stop
resolving.

## Limits

Only Fork, BetterDisplay and CodexBar of these were installed on the machine
where the entries were written. Every other path comes from the cask
maintainers, not from an observed install.
