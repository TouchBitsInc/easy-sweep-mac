import Foundation
import Testing

@testable import EasySweepCatalog

/// `keeps` names a row an unattended clean spares. Each case is a way the
/// flag could say less than it seems to, or vanish on a build that reads it.
@Suite("Kept rows")
struct KeepsTests {

    let entries = EasySweepCatalog.all

    /// The flag names a row, so an entry carrying it has rows to name.
    @Test func keepsNeedsRows() {
        for entry in entries where entry.keeps != nil {
            #expect(!entry.subfolders.isEmpty, "\(entry.id) keeps a row but has none")
        }
    }

    /// The three Device Support folders are the reason the flag exists, and
    /// they carry it — the consumer's own id-suffix rule is retired for this.
    @Test func deviceSupportKeepsItsNewestBuild() {
        for id in ["ios-device-support", "tvos-device-support", "watchos-device-support"] {
            #expect(entries.first { $0.id == id }?.keeps == .newest, Comment(rawValue: id))
        }
        #expect(entries.first { $0.id == "edge-updater-staging" }?.keeps == .newest)
        #expect(entries.first { $0.id == "derived-data" }?.keeps == nil)
    }

    /// Absent is nil, not an error: every entry before the flag existed still
    /// decodes.
    @Test func absentKeepsIsNil() throws {
        let json = """
        {"id":"example","name":"Example","detail":"Rebuilt on use.",
         "path":"~/Library/Caches/example","risk":"safe"}
        """
        let entry = try JSONDecoder().decode(EasySweepCatalog.Entry.self, from: Data(json.utf8))
        #expect(entry.keeps == nil)
    }

    /// A value this build does not know fails the entry rather than reading
    /// as nil. Nil would have an older build clean the row a newer catalog
    /// says to keep; a missing row is the safer failure.
    @Test func anUnknownKeepsValueDropsTheEntry() {
        let json = """
        {"id":"example","name":"Example","detail":"Rebuilt on use.",
         "path":"~/Library/Caches/example","subfolders":["*"],"risk":"safe","keeps":"oldest"}
        """
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(EasySweepCatalog.Entry.self, from: Data(json.utf8))
        }
    }
}
