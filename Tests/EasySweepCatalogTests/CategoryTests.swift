import Foundation
import Testing
@testable import EasySweepCatalog

struct CategoryTests {
    @Test func appDataIsTheCanonicalSwiftCase() throws {
        func label(_ category: EasySweepCatalog.Category) -> String {
            switch category {
            case .appData: "Apps"
            case .developer: "Developer"
            case .system: "System"
            }
        }
        #expect(label(.appData) == "Apps")
        #expect(EasySweepCatalog.Category.appData.rawValue == "appData")
        #expect(EasySweepCatalog.Category.allCases.count == 3)
        let encoded = try JSONEncoder().encode(EasySweepCatalog.Category.appData)
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
