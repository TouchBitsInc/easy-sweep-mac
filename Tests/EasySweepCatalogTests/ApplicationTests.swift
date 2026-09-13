import Foundation
import Testing
@testable import EasySweepCatalog

struct ApplicationTests {
    @Test func nestedApplicationsExposeEveryLeafExactlyOnce() throws {
        let data = try #require(EasySweepCatalog.catalogData(in: .appData))
        let raw = try #require(JSONSerialization.jsonObject(with: data) as? [[String: Any]])
        #expect(raw.count == EasySweepCatalog.applications.count)
        let rawLeaves = try raw.flatMap { try #require($0["entries"] as? [[String: Any]]) }
        let leaves = EasySweepCatalog.entries(in: .appData)
        #expect(rawLeaves.count == leaves.count)
        #expect(Set(leaves.map(\.id)).count == leaves.count)
        #expect(Set(EasySweepCatalog.applications.map(\.id)).count == raw.count)
        for application in EasySweepCatalog.applications {
            #expect(!application.entries.isEmpty)
            for entry in application.entries {
                #expect(EasySweepCatalog.application(containing: entry.id)?.id == application.id)
            }
        }
    }

    @Test func appHeadingsAndChildrenAreLocalizedIndependently() throws {
        let application = try #require(EasySweepCatalog.application(containing: "chrome-cache"))
        #expect(application.id == "chrome")
        #expect(application.name == "Google Chrome")
        #expect(application.entries.map(\.id) == ["chrome-cache", "chrome-site-cache", "chrome-ai-model", "chrome-shader-cache"])
        #expect(application.entries.map(\.risk) == [.safe, .cautious, .cautious, .safe])
        #expect(application.entries.map(\.name) == ["Cache", "Site Data", "AI Model", "Graphics Cache"])
        let locales = CatalogValidationTests().supportedLocales
        for app in EasySweepCatalog.applications {
            for locale in locales {
                #expect(app.localizations[locale]?.name?.isEmpty == false)
                #expect(!app.localizedName(for: Locale(identifier: locale)).isEmpty)
            }
        }
        #expect(application.localizedName(for: Locale(identifier: "xx")) == application.name)
    }

    @Test func malformedChildDoesNotBlankItsApplication() throws {
        let json = #"{"id":"example","name":"Example","entries":[{"id":"cache","name":"Cache","detail":"Rebuilt on launch.","path":"~/Library/Caches/Example","risk":"safe"},{"id":"invalid","risk":"unknown"}]}"#
        let app = try JSONDecoder().decode(EasySweepCatalog.Application.self, from: Data(json.utf8))
        #expect(app.entries.map(\.id) == ["cache"])
    }

    @Test(arguments: ["appData"])
    func appDataRoundTrips(_ name: String) throws {
        let category = try JSONDecoder().decode(EasySweepCatalog.Category.self, from: JSONEncoder().encode(name))
        #expect(category == .appData)
        #expect(try JSONDecoder().decode(String.self, from: JSONEncoder().encode(category)) == "appData")
    }

    @Test func namedCachesNeverResolveCredentialsOrUnknownApplications() throws {
        let home = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: home) }
        let protected = [
            ".cache/huggingface/token", ".cache/huggingface/stored_tokens",
            ".cache/huggingface/datasets/local.arrow", ".cache/unknown/important.txt",
            ".cache/torch/hub/local-project/source.py",
            "Library/Application Support/Slack/Local Storage/db",
            "Library/Application Support/Slack/IndexedDB/db",
            "Library/Application Support/Unknown/Cache/important.txt",
            "Library/Application Support/Spotify/PersistentCache/preferences",
        ]
        let cacheFiles = [
            ".cache/huggingface/hub/models--test/blobs/weights",
            ".cache/torch/hub/checkpoints/weights.pth", ".cache/uv/wheels/package",
            "Library/Application Support/Slack/Cache/http",
            "Library/Application Support/Slack/Code Cache/script",
            "Library/Application Support/Spotify/PersistentCache/Storage/audio",
        ]
        for file in protected + cacheFiles {
            let url = home.appending(path: file)
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Data([1]).write(to: url)
        }
        let paths = EasySweepCatalog.all.flatMap { $0.resolved(home: home) }
        func matches(_ file: String) -> Int {
            let path = home.appending(path: file).path
            return paths.filter { path == $0.path || path.hasPrefix($0.path + "/") }.count
        }
        for file in protected { #expect(matches(file) == 0, "\(file) must be protected") }
        for file in cacheFiles { #expect(matches(file) == 1, "\(file) must be counted exactly once") }
    }
}
