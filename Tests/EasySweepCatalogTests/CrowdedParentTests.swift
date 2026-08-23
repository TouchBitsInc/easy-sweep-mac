import Foundation
import Testing

@testable import EasySweepCatalog

/// A pattern's matches must not depend on how crowded their parent is.
///
/// `~/Library/Application Support` holds well over a hundred entries on an
/// ordinary Mac, and `matchLimit` is 32 — so if the cap were ever applied to the
/// directory listing rather than to the matches, a pattern like `*/Cache` would
/// silently resolve only the alphabetically-first siblings and miss the rest.
/// The bug would be invisible: fewer rows, no error.
@Suite("Crowded parents")
struct CrowdedParentTests {

    @Test func matchesAreFoundAmongManyUnrelatedSiblings() throws {
        let root = FileManager.default.temporaryDirectory
            .appending(path: "CrowdedTests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let parent = root.appending(path: "Caches/Vendor")

        // Non-matching siblings, named so they sort *before* every match.
        for index in 0..<120 {
            try FileManager.default.createDirectory(
                at: parent.appending(path: String(format: "AAA-other-%03d", index)),
                withIntermediateDirectories: true
            )
        }
        // Three matches, sorting last.
        for name in ["zzzToolA", "zzzToolB", "zzzToolC"] {
            try FileManager.default.createDirectory(
                at: parent.appending(path: name), withIntermediateDirectories: true
            )
        }

        let hits = PathPattern.resolve("~/Caches/Vendor/zzzTool*", home: root)
        #expect(hits.count == 3, "found \(hits.map(\.lastPathComponent))")
    }

    /// The same question one level deeper, which is the shape a real entry uses:
    /// `~/Library/Application Support/*/Cache`.
    @Test func aRemainderSegmentResolvesPastACrowdedParent() throws {
        let root = FileManager.default.temporaryDirectory
            .appending(path: "CrowdedTests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let parent = root.appending(path: "Library/Application Support")

        for index in 0..<120 {
            try FileManager.default.createDirectory(
                at: parent.appending(path: String(format: "AAA-app-%03d", index)),
                withIntermediateDirectories: true
            )
        }
        // Only this one has the cache folder, and it sorts after all the noise.
        try FileManager.default.createDirectory(
            at: parent.appending(path: "zzzChatApp/Cache"), withIntermediateDirectories: true
        )

        let hits = PathPattern.resolve("~/Library/Application Support/*/Cache", home: root)
        #expect(hits.count == 1, "found \(hits.map(\.path))")
    }
}
