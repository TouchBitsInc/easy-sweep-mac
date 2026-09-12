import Foundation
import Testing
@testable import EasySweepCatalog

struct DeviceBackupTests {
    // Apple documents the backup root and per-backup deletion here:
    // https://support.apple.com/108809
    @Test func deviceBackupsAreGranularAndDestructive() throws {
        let entry = try #require(EasySweepCatalog.entries(in: .system).first { $0.id == "ios-device-backups" })
        #expect(entry.risk == .destructive)
        #expect(entry.isGranular)
        #expect(entry.path == "~/Library/Application Support/MobileSync/Backup")
        #expect(entry.subfolders == ["*"])
    }

    @Test func resolutionIncludesIndividualBackupsWithoutOtherMobileSyncData() throws {
        let home = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: home) }
        for path in ["Backup/phone", "Backup/tablet", "OtherSyncData"] {
            try FileManager.default.createDirectory(
                at: home.appending(path: "Library/Application Support/MobileSync/" + path),
                withIntermediateDirectories: true)
        }
        let entry = try #require(EasySweepCatalog.entries(in: .system).first { $0.id == "ios-device-backups" })
        #expect(Set(entry.resolved(home: home).map(\.lastPathComponent)) == ["phone", "tablet"])
    }
}
