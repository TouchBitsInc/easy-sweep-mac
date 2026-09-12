import Foundation
import Testing
@testable import EasySweepCatalog

@Suite("Protected application data")
struct ProtectedDataTests {
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
