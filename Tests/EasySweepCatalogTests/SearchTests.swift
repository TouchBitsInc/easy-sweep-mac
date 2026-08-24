import Foundation
import Testing

@testable import EasySweepCatalog

/// The search rules are the one part of this package that describes a *pattern*
/// rather than a path, so what a contributed rule may not do is the whole of the
/// review. These are the checks a maintainer cannot do by eye.
@Suite("Search rules")
struct SearchTests {

    let rules = EasySweepCatalog.searchRules

    @Test func theRulesLoad() {
        #expect(!rules.isEmpty)
    }

    @Test func idsAreUniqueSlugs() {
        var seen: Set<String> = []
        for rule in rules {
            #expect(seen.insert(rule.id).inserted, "duplicate rule \(rule.id)")
            #expect(
                rule.id.allSatisfy { $0.isLowercase || $0.isNumber || $0 == "-" },
                "\(rule.id) should be lowercase, digits and hyphens"
            )
        }
    }

    // MARK: - Where it looks

    /// One literal path, like an entry — that is what makes the folder a
    /// sandboxed consumer must be granted readable without touching the disk. A
    /// rule that applies to two folders is two rules.
    @Test func pathsAreLiteralOrAbsent() {
        for rule in rules {
            guard let path = rule.path else { continue }
            let reason = PathPattern.rejectionReason(forPath: path)
            #expect(reason == nil, "\(rule.id): \(path) — \(reason ?? "")")
        }
    }

    /// **The rule that keeps us honest about other people's Macs.** `~/Projects`
    /// is one developer's habit, not a convention, so a shipped root may only be
    /// somewhere macOS itself defines. Everything else waits for the user.
    @Test func shippedRootsAreOnlyFoldersMacOSDefines() {
        let defined: Set<String> = [
            "~/Downloads", "~/Desktop", "~/Documents", "~/Movies", "~/Music", "~/Pictures",
        ]
        for rule in rules {
            guard let path = rule.path else { continue }
            #expect(defined.contains(path), "\(rule.id) ships \(path), which is a guess")
        }
    }

    /// A tree rule with no path waits for the user to say where. A flat one with
    /// no path would search nothing and say nothing about why.
    @Test func flatRulesNameTheirFolder() {
        for rule in rules where rule.engine == .flat {
            #expect(rule.path != nil, "\(rule.id) is flat but names no folder")
        }
    }

    /// Depth is what stops a root someone adds from running for hours.
    @Test func treeRulesAreBounded() {
        for rule in rules where rule.engine == .tree {
            #expect(rule.depth >= 1 && rule.depth <= 6, "\(rule.id) has depth \(rule.depth)")
        }
    }

    // MARK: - What it looks for

    /// Each engine reads one kind of rule. A directory name on a flat rule, or an
    /// extension on a tree rule, matches nothing and says nothing about why.
    @Test func fieldsSuitTheEngine() {
        for rule in rules {
            switch rule.engine {
            case .tree:
                #expect(!rule.names.isEmpty, "\(rule.id) names no directories")
                #expect(rule.extensions.isEmpty, "\(rule.id) has extensions on a tree rule")
            case .flat:
                #expect(!rule.extensions.isEmpty, "\(rule.id) names no extensions")
                #expect(rule.names.isEmpty, "\(rule.id) has directory names on a flat rule")
            }
        }
    }

    /// **The guard that matters.** A directory name is a guess unless something
    /// beside it proves what made it — `target` is a Rust build only next to a
    /// `Cargo.toml`. A name may go unmarked only when it means nothing else
    /// anywhere, which is true of Python's caches and very little else.
    @Test func directoryNamesCarryAMarker() {
        let allowedUnmarked: Set<String> = ["__pycache__", ".pytest_cache"]
        for rule in rules where rule.besideAnyOf.isEmpty {
            for name in rule.names {
                #expect(
                    allowedUnmarked.contains(name),
                    "\(rule.id): \(name) needs a marker file beside it"
                )
            }
        }
    }

    /// A `.zip` is as likely to be someone's only copy of something as it is to
    /// be an installer, and a `.app` is an application.
    @Test func noExtensionThatCouldBeSomeonesOnlyCopy() {
        let refused: Set<String> = ["zip", "tar", "gz", "app", "pdf", "jpg", "png", "mov", "mp4"]
        for rule in rules {
            for ext in rule.extensions {
                #expect(!refused.contains(ext), "\(rule.id): \(ext) is not an installer")
                #expect(ext == ext.lowercased(), "\(rule.id): \(ext) must be lowercase")
                #expect(!ext.hasPrefix("."), "\(rule.id): \(ext) must not carry a dot")
            }
        }
    }

    /// Something that could still be wanted has to have sat there a while.
    /// Something nothing can open does not.
    @Test func installersWaitBeforeBeingOffered() {
        for rule in rules where rule.extensions.contains("dmg") {
            let days = rule.minimumAgeDays ?? 0
            #expect(days >= 7, "\(rule.id) offers installers after \(days) days")
        }
    }

    @Test func everyRuleExplainsItself() {
        for rule in rules {
            #expect(!rule.name.isEmpty, "\(rule.id) has no name")
            #expect(rule.detail.count > 40, "\(rule.id)'s detail says too little")
            #expect(
                !rule.detail.localizedCaseInsensitiveContains("safe to delete"),
                "\(rule.id): say what regenerates it, not that it is safe"
            )
        }
    }

    // MARK: - Matching

    @Test func aDirectoryMatchesOnlyBesideItsMarker() throws {
        let rule = try #require(rules.first { $0.id == "build-output" })

        #expect(rule.matches(directory: "node_modules", siblings: ["package.json"]))
        #expect(!rule.matches(directory: "node_modules", siblings: ["holiday.jpg"]))
        #expect(!rule.matches(directory: "Documents", siblings: ["package.json"]))
    }

    @Test func aFileMatchesOnlyOnceItIsOldEnough() throws {
        let installers = try #require(rules.first { $0.id == "installers-downloads" })
        let partials = try #require(rules.first { $0.id == "partial-downloads-downloads" })
        let day: TimeInterval = 24 * 60 * 60

        #expect(installers.matches(extension: "dmg", age: 30 * day))
        #expect(!installers.matches(extension: "dmg", age: day))
        // An unknown age is unproven, and unproven is not offered.
        #expect(!installers.matches(extension: "dmg", age: nil))
        #expect(!installers.matches(extension: "zip", age: 30 * day))

        // Nothing can open a partial download, so it needs no wait.
        #expect(partials.matches(extension: "crdownload", age: nil))
    }

    /// A rule reads only the fields its own engine uses, so a mistake in the
    /// file cannot make a tree rule start matching files.
    @Test func anEngineIgnoresTheOtherOnesFields() throws {
        let tree = try #require(rules.first { $0.engine == .tree })
        #expect(!tree.matches(extension: "dmg", age: nil))

        let flat = try #require(rules.first { $0.engine == .flat })
        #expect(!flat.matches(directory: "node_modules", siblings: ["package.json"]))
    }
}
