import Foundation
import Testing
@testable import EasySweepCatalog

@Suite("Protected application data")
struct ProtectedDataTests {
    @Test func expandedCachesAreCountedOnceWithoutSelectingNeighboringData() throws {
        let caches: [String: String] = [
            ".pyenv/cache/Python.tar.xz": "pyenv-downloads",
            ".rbenv/cache/ruby.tar.gz": "rbenv-downloads",
            ".gem/specs/rubygems.org/specs.gz": "rubygems-specs",
            ".cache/gem/specs/rubygems.org/specs.gz": "rubygems-xdg-cache",
            ".cache/gem/gems/rake.gem": "rubygems-xdg-cache",
            ".yarn/berry/cache/package.zip": "yarn-berry-cache",
            ".cache/zig/o/hash/object.o": "zig-cache",
            ".hex/packages/hexpm/package.tar": "hex-packages",
            ".cache/hex/packages/hexpm/package.tar": "hex-xdg-packages",
            ".opam/download-cache/sha256/hash": "opam-downloads",
            ".cache/puppeteer/chrome/mac-version/chrome": "puppeteer-browsers",
            "Library/Caches/Sublime Text/Index/index": "sublime-text-cache",
            ".npm/_prebuilds/archive.tar.gz": "npm-prebuilds",
            ".npm/_logs/debug.log": "npm-logs",
            "Library/Application Support/Code/logs/session/main.log": "vscode-logs",
            ".kube/cache/http/response": "kubectl-cache",
            ".kube/cache/discovery/server/serverresources.json": "kubectl-cache",
            "Library/Application Support/Firefox/Profiles/example.default/cache2/entries/response": "firefox-profile-cache",
            "Library/Caches/com.colliderli.iina/thumb_cache/thumbnail": "iina-thumbnails",
            "Library/Caches/org.videolan.vlc/art/arturl/cover.jpg": "vlc-cache",
            "Library/Caches/com.epicgames.EpicGamesLauncher/webcache/Cache/response": "epic-games-web-cache",
            "Library/Application Support/obsidian/Code Cache/js/response": "obsidian-web-cache",
            "Library/Application Support/Figma/Cache/response": "figma-web-cache",
            "Library/Application Support/Figma/DesktopProfile/Code Cache/js/response": "figma-web-cache",
            "Library/Containers/com.microsoft.Word/Data/Library/Caches/response": "microsoft-word-cache",
            "Library/Containers/com.microsoft.Excel/Data/Library/Caches/response": "microsoft-excel-cache",
            "Library/Containers/com.microsoft.Powerpoint/Data/Library/Caches/response": "microsoft-powerpoint-cache",
            "Library/Containers/com.microsoft.Outlook/Data/Library/Caches/response": "microsoft-outlook-cache",
            "Library/Containers/com.microsoft.Office365ServiceV2/Data/Caches/com.microsoft.Office365ServiceV2/response": "office-service-cache",
            "Library/Containers/com.microsoft.Office365ServiceV2/Data/Library/Caches/com.microsoft.Office365ServiceV2/response": "office-service-library-cache",
        ]
        let protected = [
            ".pyenv/versions/current/bin/python", ".pyenv/version",
            ".rbenv/versions/current/bin/ruby", ".rbenv/shims/ruby",
            ".gem/credentials", ".gem/ruby/current/gems/package/lib/source.rb",
            ".yarn/berry/metadata/registry.json", ".yarnrc.yml",
            ".hex/hex.config", ".hex/hexpm/repository-key",
            ".opam/default/bin/ocaml", ".opam/config", ".opam/repo/repos-config",
            ".kube/config", ".kube/plugins/credentials.json", ".kube/cache/new-store/value",
            ".cache/pre-commit/patch123", ".cache/node/corepack/version/bin/yarn",
            "Library/Application Support/Code/User/History/local/file",
            "Library/Application Support/Code/User/workspaceStorage/workspace/state.vscdb",
            "Library/Application Support/Code/Backups/unsaved.txt",
            "Library/Application Support/Sublime Text/Local/Session.sublime_session",
            "Library/Application Support/Firefox/Profiles/example.default/logins.json",
            "Library/Application Support/Firefox/Profiles/example.default/key4.db",
            "Library/Application Support/Firefox/Profiles/example.default/sessionstore-backups/recovery.jsonlz4",
            "Library/Caches/com.colliderli.iina/screenshot_cache/screenshot.png",
            "Library/Application Support/com.colliderli.iina/watch_later/position",
            "Library/Application Support/org.videolan.vlc/ml.xspf",
            "Library/Caches/com.epicgames.EpicGamesLauncher/new-store/value",
            "Library/Application Support/Epic/EpicGamesLauncher/Data/Manifests/game.item",
            "Library/Application Support/obsidian/IndexedDB/vault/state",
            "Library/Application Support/obsidian/Local Storage/leveldb/settings",
            "Library/Application Support/obsidian/obsidian.json",
            "Library/Application Support/Figma/DesktopProfile/IndexedDB/offline-edits",
            "Library/Application Support/Figma/DesktopProfile/Local Storage/leveldb/state",
            "Library/Application Support/Figma/DesktopProfile/Service Worker/ScriptCache/worker.js",
            "Library/Application Support/Figma/settings",
            "Library/Containers/com.microsoft.Word/Data/Documents/wef/add-in.xml",
            "Library/Containers/com.microsoft.Excel/Data/Library/Application Support/Microsoft/Office/16.0/Wef/add-in.xml",
            "Library/Containers/com.microsoft.Powerpoint/Data/Documents/presentation.pptx",
            "Library/Containers/com.microsoft.Outlook/Data/Library/Application Support/Microsoft/Outlook/profile/mail",
            "Library/Containers/com.microsoft.Office365ServiceV2/Data/Documents/state",
            "Documents/vault/note.md", "Documents/project/.ruff_cache/state",
            "Documents/project/.mypy_cache/state", "Documents/project/.pytest_cache/state",
            "Documents/project/node_modules/.cache/webpack/bundle", "Documents/VM/disk.qcow2",
            "Library/Application Support/Steam/steamapps/common/game/save.dat",
        ]
        let home = try fixture(Array(caches.keys) + protected)
        defer { try? FileManager.default.removeItem(at: home) }
        let selections = EasySweepCatalog.all.flatMap { entry in
            PathPattern.resolve(path: entry.path, subfolders: entry.subfolders, home: home)
                .map { (entry.id, $0) }
        }
        for (path, expectedOwner) in caches {
            let owners = selections.filter { isSelected(path, home: home, selections: [$0.1]) }.map(\.0)
            #expect(owners == [expectedOwner], "Incorrect or duplicate selection for \(path): \(owners)")
        }
        for path in protected {
            #expect(!isSelected(path, home: home, selections: selections.map(\.1)), "User data selected: \(path)")
        }
    }

    @Test func expandedBrowserCachesExcludeProfilesAndPasswords() throws {
        let browserIDs = ["chrome", "edge", "brave", "arc", "vivaldi", "opera",
                          "opera-gx", "chromium", "yandex", "chrome-canary"]
        for id in browserIDs {
            let entry = try #require(EasySweepCatalog.all.first { $0.id == "\(id)-shader-cache" })
            let base = String(entry.path.dropFirst(2))
            let caches = ["ShaderCache/response", "GrShaderCache/response", "GraphiteDawnCache/response",
                          "Default/Code Cache/js/response", "Profile 1/Code Cache/js/response"]
                .map { "\(base)/\($0)" }
            let protected = ["Local State", "Default/Bookmarks", "Default/Login Data", "Default/Cookies",
                             "Default/Sessions/session", "Default/IndexedDB/database",
                             "Default/Service Worker/ScriptCache/worker.js", "Default/Preferences"]
                .map { "\(base)/\($0)" }
            let home = try fixture(caches + protected)
            defer { try? FileManager.default.removeItem(at: home) }
            let selections = allSelections(home: home)
            for path in caches {
                #expect(selections.filter { isSelected(path, home: home, selections: [$0]) }.count == 1)
            }
            for path in protected {
                #expect(!isSelected(path, home: home, selections: selections), "Profile selected: \(path)")
            }
        }
    }

    @Test func downloadedToolsAndWebDataRequireExplicitCleaning() throws {
        for id in ["pyenv-downloads", "rbenv-downloads", "rubygems-xdg-cache", "yarn-berry-cache",
                   "hex-packages", "hex-xdg-packages", "opam-downloads", "puppeteer-browsers",
                   "npm-prebuilds", "npm-logs", "vscode-logs", "epic-games-web-cache",
                   "obsidian-web-cache", "figma-web-cache", "microsoft-word-cache",
                   "microsoft-excel-cache", "microsoft-powerpoint-cache", "microsoft-outlook-cache",
                   "office-service-cache", "office-service-library-cache"] {
            let entry = try #require(EasySweepCatalog.all.first { $0.id == id })
            #expect(entry.risk == .cautious)
            #expect(!entry.autoClean)
        }
    }

    @Test func cacheSelectionsExcludePersistentState() throws {
        let caches = [
            "Library/Caches/pypoetry/artifacts/wheel.whl",
            "Library/Caches/pypoetry/cache/repositories/pypi/response",
            "Library/Caches/deno/gen/compiled.js",
            "Library/Caches/deno/remote/https/example.com/module.ts",
            "Library/Caches/deno/npm/registry.npmjs.org/package/index.js",
            ".expo/expo-go/response",
            ".expo/android-apk-cache/client.apk",
            ".expo/ios-simulator-app-cache/client.app/executable",
            ".expo/native-modules-cache/response",
            ".expo/schema-cache/response",
        ]
        let codexProfiles = ["Default", "Default/Partitions/codex-browser-app", "codex-browser-app"]
        let codexCaches = codexProfiles.flatMap { profile in
            ["Cache", "Code Cache"].map { "Library/Caches/Codex/\(profile)/\($0)/response" }
        }
        let persistent = [
            "Library/Caches/pypoetry/virtualenvs/project/bin/python",
            "Library/Caches/deno/location_data/origin/local_storage",
            "Library/Caches/deno/origin_data/origin/database",
            "Library/Caches/deno/deno_history.txt",
            "Library/Caches/deno/dl/deno",
            ".expo/state.json",
            ".expo/settings.json",
            ".expo/new-unreviewed-data/value",
        ] + codexProfiles.flatMap { profile in
            ["Cookies", "Network/Cookies", "Local Storage/leveldb/state", "IndexedDB/database",
             "Sessions/session", "Preferences"].map { "Library/Caches/Codex/\(profile)/\($0)" }
        }
        let root = try fixture(caches + codexCaches + persistent)
        defer { try? FileManager.default.removeItem(at: root) }
        let selected = allSelections(home: root)
        for path in caches + codexCaches {
            #expect(isSelected(path, home: root, selections: selected), "Cache omitted: \(path)")
        }
        for path in persistent {
            #expect(!isSelected(path, home: root, selections: selected), "Persistent state selected: \(path)")
        }
    }

    @Test func geminiConversationsRequireDestructiveCleaning() throws {
        let conversations = [".gemini/tmp/project-a/chats/session.json", ".gemini/tmp/project-b/chats/session.json"]
        let protected = [".gemini/tmp/project-a/shell_history", ".gemini/tmp/project-a/plans/plan.md",
                         ".gemini/settings.json"]
        let root = try fixture(conversations + protected)
        defer { try? FileManager.default.removeItem(at: root) }
        let entry = try #require(EasySweepCatalog.all.first { $0.id == "gemini-tmp" })
        #expect(entry.risk == .destructive)
        #expect(!entry.autoClean)
        let selected = allSelections(home: root)
        let balanced = allSelections(home: root, maximumRisk: .cautious)
        for path in conversations {
            #expect(isSelected(path, home: root, selections: selected))
            #expect(!isSelected(path, home: root, selections: balanced))
        }
        for path in protected {
            #expect(!isSelected(path, home: root, selections: selected))
        }
    }

    @Test func chromiumScriptStoresStayOutsideCleanup() throws {
        let entries = EasySweepCatalog.all.filter {
            $0.subfolders.contains { $0.hasSuffix("Service Worker/CacheStorage") }
        }
        #expect(!entries.isEmpty)
        for entry in entries {
            let relativeRoot = String(entry.path.dropFirst(2))
            let stores = entry.subfolders.filter { $0.hasSuffix("Service Worker/CacheStorage") }
                .map { "\(relativeRoot)/\($0.replacingOccurrences(of: "*", with: "Default"))" }
            let caches = stores.map { "\($0)/response" }
            let scripts = stores.map { "\($0.replacingOccurrences(of: "CacheStorage", with: "ScriptCache"))/worker.js" }
            let root = try fixture(caches + scripts)
            defer { try? FileManager.default.removeItem(at: root) }
            let selected = allSelections(home: root)
            for path in caches { #expect(isSelected(path, home: root, selections: selected)) }
            for path in scripts {
                #expect(!isSelected(path, home: root, selections: selected), "\(entry.id) selects registered worker scripts")
            }
        }
    }

    @Test func executableVersionsAreNotStaticCleanupTargets() throws {
        let executables = [".local/share/claude/versions/current", ".local/share/claude/versions/old",
                           ".local/share/cursor-agent/versions/current/agent",
                           ".copilot/pkg/universal/current/copilot"]
        let root = try fixture(executables)
        defer { try? FileManager.default.removeItem(at: root) }
        let selected = allSelections(home: root)
        for path in executables {
            #expect(!isSelected(path, home: root, selections: selected), "Executable selected without active-version protection: \(path)")
        }
    }

    private func allSelections(home: URL, maximumRisk: EasySweepCatalog.Entry.Risk = .destructive) -> [URL] {
        EasySweepCatalog.all.filter { $0.risk <= maximumRisk }.flatMap {
            PathPattern.resolve(path: $0.path, subfolders: $0.subfolders, home: home)
        }
    }

    private func isSelected(_ path: String, home: URL, selections: [URL]) -> Bool {
        let absolute = home.appending(path: path).path
        return selections.contains { absolute == $0.path || absolute.hasPrefix($0.path + "/") }
    }

    private func fixture(_ files: [String]) throws -> URL {
        let root = FileManager.default.temporaryDirectory.appending(path: "ProtectedDataTests-\(UUID().uuidString)")
        for path in files {
            let url = root.appending(path: path)
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Data("fixture".utf8).write(to: url)
        }
        return root
    }
}
