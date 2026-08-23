import Foundation
import Testing

#if canImport(AppKit)
import AppKit
#endif

@testable import EasySweepCatalog

/// These are the review that a maintainer cannot do by eye on every pull
/// request. Each one maps to a way the catalog has gone wrong or could.
///
/// What they cannot check is the claim that matters: that a path really is a
/// regenerable cache. The tool isn't installed on the runner. That is the
/// irreducible trust boundary, and the reason a pull request has to cite
/// upstream documentation.
@Suite("Catalog validation")
struct CatalogValidationTests {

    let entries = EasySweepCatalog.all

    @Test func everyCategoryLoads() {
        // Qualified: bare `Category` resolves to Darwin's own C typealias.
        for category in EasySweepCatalog.Category.allCases {
            #expect(!EasySweepCatalog.entries(in: category).isEmpty, "\(category.rawValue) is empty")
        }
        #expect(entries.count >= 40)
    }

    // MARK: - Identity

    @Test func idsAreUniqueAcrossEveryFile() {
        var seen: Set<String> = []
        for entry in entries {
            #expect(seen.insert(entry.id).inserted, "duplicate id \(entry.id)")
        }
    }

    @Test func idsAreSlugs() {
        for entry in entries {
            #expect(
                entry.id.allSatisfy { $0.isLowercase || $0.isNumber || $0 == "-" },
                "\(entry.id) should be lowercase, digits and hyphens"
            )
        }
    }

    // MARK: - Paths

    /// The rule that would have caught adding `~/.cache/uv` while `xdg-cache`
    /// already sweeps `~/.cache`: the bytes are then counted twice, once in the
    /// section total and again in the bar.
    @Test func noPathContainsAnother() {
        let all = entries.flatMap { entry in entry.paths.map { (entry.id, $0) } }
        for (idA, pathA) in all {
            for (idB, pathB) in all where idA != idB {
                #expect(
                    !(pathB + "/").hasPrefix(pathA + "/"),
                    "\(idB)'s \(pathB) sits inside \(idA)'s \(pathA) — sizes would double-count"
                )
            }
        }
    }

    @Test func pathsAreTildeRelativeAndWellFormed() {
        for entry in entries {
            #expect(!entry.paths.isEmpty, "\(entry.id) names no path")
            for path in entry.paths {
                #expect(
                    PathPattern.rejectionReason(for: path) == nil,
                    "\(entry.id): \(path) — \(PathPattern.rejectionReason(for: path) ?? "")"
                )
            }
        }
    }

    /// An entry spanning two roots is half usable under the sandbox — one
    /// folder granted, the other not — with no honest way to show that on a
    /// single row.
    @Test func eachEntryHasExactlyOneGrantRoot() {
        for entry in entries {
            #expect(
                entry.grantRoots.count == 1,
                "\(entry.id) spans \(entry.grantRoots.sorted()) — split it"
            )
        }
    }

    /// Adding a path silently adds a permission the sandboxed build must ask
    /// for, so the set of `Library` roots is closed and adding to it is a
    /// deliberate act by a maintainer rather than a side effect of a merge.
    ///
    /// Dot-directories are allowed as a class: they are already narrow, a
    /// contributor cannot reach anything sensitive through one, and enumerating
    /// them would mean editing this list for every new tool.
    @Test func grantRootsAreOnTheAllowlist() {
        let allowed: Set<String> = [
            "Library/Caches",
            "Library/Developer",
            "Library/Application Support",
            "Library/Logs",
            // CoreDevice keeps staged bundles under its own container.
            "Library/Containers",
            // pnpm puts its content-addressable store outside Caches.
            "Library/pnpm",
        ]
        for entry in entries {
            for root in entry.grantRoots {
                #expect(
                    allowed.contains(root) || root.hasPrefix("."),
                    "\(entry.id) needs \(root), which is neither an allowed Library folder nor a dot-directory"
                )
            }
        }
    }

    // MARK: - Presentation

    /// An unknown SF Symbol renders as nothing at all — not a placeholder, not
    /// a fallback. A typo here is an invisible row icon.
    @Test func symbolsResolve() throws {
        #if canImport(AppKit)
        for entry in entries {
            guard let symbol = entry.symbol else { continue }
            #expect(
                NSImage(systemSymbolName: symbol, accessibilityDescription: nil) != nil,
                "\(entry.id): \(symbol) is not an SF Symbol on this OS"
            )
        }
        #endif
    }

    @Test func brandColoursParse() {
        for entry in entries {
            guard let hex = entry.brandColor else { continue }
            #expect(hex.hasPrefix("#") && hex.count == 7, "\(entry.id): \(hex) is not #RRGGBB")
            let isHex = hex.dropFirst().allSatisfy { $0.isHexDigit }
            #expect(isHex, "\(entry.id): \(hex) has non-hex characters")
        }
    }

    /// `detail` is what someone reads immediately before deleting, so it states
    /// the mechanism rather than offering reassurance.
    @Test func detailsExplainRatherThanReassure() {
        for entry in entries {
            #expect(!entry.detail.isEmpty, "\(entry.id) has no detail")
            #expect(
                !entry.detail.localizedCaseInsensitiveContains("safe to delete"),
                "\(entry.id): say what regenerates it, not that it is safe — risk already carries that"
            )
        }
    }
}

@Suite("Path patterns")
struct PathPatternTests {

    @Test func literalPathsAreAccepted() {
        #expect(PathPattern.rejectionReason(for: "~/Library/Caches/Homebrew") == nil)
        #expect(PathPattern.rejectionReason(for: "~/.npm/_cacache") == nil)
    }

    @Test func absolutePathsAreRefused() {
        #expect(PathPattern.rejectionReason(for: "/Library/Caches") != nil)
        #expect(PathPattern.rejectionReason(for: "/etc/passwd") != nil)
    }

    /// The whole point of the anchor rule: a pattern must never be able to name
    /// the home directory's own contents.
    @Test func wildcardsNeedTwoLiteralSegments() {
        #expect(PathPattern.rejectionReason(for: "~/*") != nil)
        #expect(PathPattern.rejectionReason(for: "~/Library/*") != nil)
        #expect(PathPattern.rejectionReason(for: "~/Library/Caches/Google/AndroidStudio*") == nil)
    }

    @Test func recursiveGlobsAreNotRepresentable() {
        #expect(PathPattern.rejectionReason(for: "~/Library/Caches/**/tmp") != nil)
    }

    @Test func traversalIsRefused() {
        #expect(PathPattern.rejectionReason(for: "~/Library/Caches/../../../etc") != nil)
    }

    @Test func oneStarPerSegment() {
        #expect(PathPattern.rejectionReason(for: "~/Library/Caches/a*b*c") != nil)
    }

    @Test func matchingIsPrefixAndSuffix() {
        #expect(PathPattern.matches(name: "AndroidStudio2024.1", pattern: "AndroidStudio*"))
        #expect(!PathPattern.matches(name: "Chrome", pattern: "AndroidStudio*"))
        #expect(PathPattern.matches(name: "gradle-8.5-bin", pattern: "gradle-*-bin"))
        #expect(!PathPattern.matches(name: "gradle-8.5-all", pattern: "gradle-*-bin"))
    }

    /// A wildcard segment must not match across a separator, or it would be a
    /// recursive glob wearing a different spelling.
    @Test func matchingDoesNotCrossSeparators() throws {
        let root = FileManager.default.temporaryDirectory
            .appending(path: "PatternTests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let deep = root.appending(path: "Caches/Vendor/ToolA/nested")
        try FileManager.default.createDirectory(at: deep, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(
            at: root.appending(path: "Caches/Vendor/Other"), withIntermediateDirectories: true
        )

        let hits = PathPattern.resolve("~/Caches/Vendor/Tool*", home: root)
        #expect(hits.count == 1)
        #expect(hits.first?.lastPathComponent == "ToolA")
    }

    @Test func resolutionIsCapped() throws {
        let root = FileManager.default.temporaryDirectory
            .appending(path: "PatternTests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let parent = root.appending(path: "Caches/Vendor")
        for index in 0..<(PathPattern.matchLimit + 20) {
            try FileManager.default.createDirectory(
                at: parent.appending(path: "Tool\(index)"), withIntermediateDirectories: true
            )
        }

        #expect(PathPattern.resolve("~/Caches/Vendor/Tool*", home: root).count == PathPattern.matchLimit)
    }
}
