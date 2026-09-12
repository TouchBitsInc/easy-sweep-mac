import Foundation
import Testing
@testable import EasySweepCatalog

struct CategoryMergeTests {
    @Test(arguments: ["browsers", "messaging", "multimedia", "aiTools", "everydayApps"])
    func savedCategoriesResolveToEverydayApps(_ key: String) throws {
        #expect(EasySweepCatalog.Category(rawValue: key) == .appData)
        let decoded = try JSONDecoder().decode(
            EasySweepCatalog.Category.self, from: JSONEncoder().encode(key))
        #expect(decoded == .appData)
        let encoded = try JSONEncoder().encode(decoded)
        #expect(try JSONDecoder().decode(String.self, from: encoded) == "appData")
    }

    @Test func threeSectionsIncludeAllApps() {
        #expect(EasySweepCatalog.Category.allCases == [.appData, .developer, .system])
        let entries = EasySweepCatalog.entries(in: .appData)
        #expect(entries.count == 87)
        let ids = Set(entries.map(\.id))
        #expect(ids.contains("chrome-cache"))
        #expect(ids.contains("spotify-cache"))
        #expect(ids.contains("ollama-models"))
        #expect(ids.contains("codex-sessions"))
        #expect(entries.contains { $0.id.contains("wechat") })
    }
}
