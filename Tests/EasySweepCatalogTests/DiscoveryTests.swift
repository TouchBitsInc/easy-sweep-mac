import Foundation
import Testing

@testable import EasySweepCatalog

/// The rule that turns a directory listing into rows. Every case is a way a
/// runtime-discovered folder could reach past what the catalog reviewed.
@Suite("Discovery roots")
struct DiscoveryTests {

    let caches = EasySweepCatalog.DiscoveryRoot(
        path: "~/Library/Caches", match: .bundleIdentifier, risk: .cautious
    )

    /// App Data is the section that discovers, and it discovers in one place.
    @Test func appDataDiscoversInstalledAppCaches() {
        let roots = EasySweepCatalog.discoveryRoots(in: .appData)
        #expect(roots == [caches])
        #expect(EasySweepCatalog.discoveryRoots(in: .developer).isEmpty)
        #expect(EasySweepCatalog.discoveryRoots(in: .system).isEmpty)
    }

    /// The root obeys the rules an entry's path does, and a discovered folder
    /// may never be cleaned unattended — nobody reviewed it.
    @Test func everyRootIsLiteralAndNeverSafe() {
        for category in EasySweepCatalog.Category.allCases {
            for root in EasySweepCatalog.discoveryRoots(in: category) {
                #expect(PathPattern.rejectionReason(forPath: root.path) == nil)
                #expect(root.risk != .safe, "\(root.path) would be eligible for automatic cleaning")
                #expect(
                    EasySweepCatalog.Entry.grantRoot(of: root.path) == "Library/Caches",
                    "\(root.path) would change what the sandboxed build asks for"
                )
            }
        }
    }

    @Test func onlyInstalledBundleIdentifiersAreOffered() {
        let found = EasySweepCatalog.discoveredFolders(
            under: caches,
            names: ["com.example.app", "com.example.uninstalled", "Some App", ".DS_Store", "com.apple.akd"],
            installedBundleIdentifiers: ["com.example.app", "com.apple.akd", "Some App"]
        )
        #expect(found.map(\.bundleIdentifier) == ["Some App", "com.example.app"])
        #expect(found.first?.path == "~/Library/Caches/Some App")
        #expect(found.allSatisfy { $0.root == caches })
    }

    /// Apple's folders are refused even when a consumer lists an Apple id as
    /// installed: clearing some of them costs a sign-in or a reboot, and the
    /// consumer's idea of "installed" is not this package's to trust there.
    @Test func appleFoldersAreRefused() {
        let found = EasySweepCatalog.discoveredFolders(
            under: caches,
            names: ["com.apple.Safari", "com.apple.dt.Xcode"],
            installedBundleIdentifiers: ["com.apple.Safari", "com.apple.dt.Xcode"]
        )
        #expect(found.isEmpty)
    }

    /// A folder an entry names — exactly, above it, or below it — is the
    /// entry's row, never a second one.
    @Test func foldersTheCatalogClaimsAreNotOfferedTwice() throws {
        let installed: Set<String> = [
            "Google", "com.colliderli.iina", "com.epicgames.EpicGamesLauncher",
            "org.videolan.vlc", "com.mitchellh.ghostty", "Homebrew",
        ]
        // Google: an entry sits below it. IINA: an entry sits below it too.
        // VLC, Ghostty, Homebrew: an entry is exactly it.
        try #require(EasySweepCatalog.all.contains { $0.path == "~/Library/Caches/Google/Chrome" })
        try #require(EasySweepCatalog.all.contains { $0.path == "~/Library/Caches/com.colliderli.iina/thumb_cache" })
        try #require(EasySweepCatalog.all.contains { $0.path == "~/Library/Caches/Homebrew" })
        try #require(EasySweepCatalog.all.contains { $0.path == "~/Library/Caches/org.videolan.vlc" })
        try #require(EasySweepCatalog.all.contains { $0.id == "ghostty-cache" })

        let found = EasySweepCatalog.discoveredFolders(
            under: caches, names: Array(installed), installedBundleIdentifiers: installed
        )
        #expect(found.isEmpty, "offered twice: \(found.map(\.path))")
    }

    /// `~/Library/Caches/*ShipIt` is declared with a wildcard; a folder it
    /// matches is claimed by it.
    @Test func wildcardClaimsAreHonoured() throws {
        try #require(EasySweepCatalog.all.contains { $0.declaredPaths.contains("~/Library/Caches/*ShipIt") })
        let found = EasySweepCatalog.discoveredFolders(
            under: caches,
            names: ["com.example.app.ShipIt", "com.example.app"],
            installedBundleIdentifiers: ["com.example.app.ShipIt", "com.example.app"]
        )
        #expect(found.map(\.bundleIdentifier) == ["com.example.app"])
    }

    /// Reading a name is not reading the disk: a listing entry with a
    /// separator in it is not a child of the root.
    @Test func namesNeverDescend() {
        let found = EasySweepCatalog.discoveredFolders(
            under: caches,
            names: ["com.example.app/inner", "../Preferences"],
            installedBundleIdentifiers: ["com.example.app/inner", "../Preferences"]
        )
        #expect(found.isEmpty)
    }

    /// A root a newer catalog declares with a match rule this build does not
    /// know is skipped on its own, leaving the roots it does know.
    @Test func anUnknownRootIsSkippedAlone() throws {
        let json = Data("""
        [
          {"path": "~/Library/Caches", "match": "bundleIdentifier", "risk": "cautious"},
          {"path": "~/Library/Containers", "match": "containerOwner", "risk": "cautious"}
        ]
        """.utf8)
        struct Skipping: Decodable {
            let root: EasySweepCatalog.DiscoveryRoot?
            init(from decoder: any Decoder) throws { root = try? EasySweepCatalog.DiscoveryRoot(from: decoder) }
        }
        let roots = try JSONDecoder().decode([Skipping].self, from: json).compactMap(\.root)
        #expect(roots == [caches])
    }
}
