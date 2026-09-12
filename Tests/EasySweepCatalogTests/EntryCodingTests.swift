import Foundation
import Testing
@testable import EasySweepCatalog

struct EntryCodingTests {
    @Test func colourIsWrittenUnderItsCurrentName() throws {
        let entry = EasySweepCatalog.Entry(
            id: "example", name: "Example", detail: "Refetched on next build.",
            path: "~/Library/Caches/example", risk: .safe, color: "#CB3837"
        )
        let written = String(decoding: try JSONEncoder().encode(entry), as: UTF8.self)
        #expect(written.contains("\"color\""))

        let decoded = try JSONDecoder().decode(
            EasySweepCatalog.Entry.self, from: Data(written.utf8))
        #expect(decoded.color == "#CB3837")
    }

    @Test(arguments: ["rustup-toolchains", "xdg-cache", "electron-http-caches", "electron-code-caches"])
    func unsupportedBroadScopesAreAbsent(_ id: String) {
        #expect(!EasySweepCatalog.all.contains { $0.id == id })
    }
}
