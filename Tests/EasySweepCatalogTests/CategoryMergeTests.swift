import Foundation
import Testing
@testable import EasySweepCatalog

struct CategoryMergeTests {
    @Test func originalSwiftCaseAndExhaustiveSwitchRemainCompatible() throws {
        // A static everydayApps alias would allow assignments but still break
        // an exhaustive switch compiled by a 2.7.x consumer.
        func legacyLabel(_ category: EasySweepCatalog.Category) -> String {
            switch category {
            case .everydayApps: "Apps"
            case .developer: "Developer"
            case .system: "System"
            }
        }
        #expect(legacyLabel(.appData) == "Apps")
        #expect(EasySweepCatalog.Category.everydayApps == .appData)
        #expect(EasySweepCatalog.Category.appData.rawValue == "appData")
        #expect(EasySweepCatalog.Category.allCases.count == 3)
        let encoded = try JSONEncoder().encode(EasySweepCatalog.Category.everydayApps)
        #expect(try JSONDecoder().decode(String.self, from: encoded) == "appData")
    }

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
