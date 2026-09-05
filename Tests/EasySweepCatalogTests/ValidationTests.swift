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
    let supportedLocales = [
        "en", "de", "es", "fr", "it", "ja", "ko", "nl", "pl",
        "pt-BR", "ru", "tr", "uk", "zh-Hans", "zh-Hant", "zh-HK"
    ]

    @Test func everyCategoryLoads() {
        // Qualified: bare `Category` resolves to Darwin's own C typealias.
        for category in EasySweepCatalog.Category.allCases {
            #expect(!EasySweepCatalog.entries(in: category).isEmpty, "\(category.rawValue) is empty")
        }
        #expect(entries.count >= 40)
    }

    /// The enum's order is what a consumer reads sections in, and System leads
    /// it — the one section that is on every Mac rather than describing a
    /// toolchain. Pinned because nothing else would notice it moving.
    @Test func systemIsTheFirstSection() {
        #expect(EasySweepCatalog.Category.allCases.first == .system)
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
    ///
    /// Compared on **declared** paths — the root joined to each subfolder — not
    /// on roots. Two entries may now legitimately share a root
    /// (`~/Library/Application Support` holds several), and comparing roots
    /// would both fail those and miss two subfolder patterns that collide.
    /// Declared rather than resolved, so the answer doesn't depend on what
    /// happens to be installed on the machine running the test.
    @Test func noPathContainsAnother() {
        let all = entries.flatMap { entry in entry.declaredPaths.map { (entry.id, $0) } }
        for (idA, pathA) in all {
            for (idB, pathB) in all where idA != idB {
                #expect(
                    !(pathB + "/").hasPrefix(pathA + "/"),
                    "\(idB)'s \(pathB) sits inside \(idA)'s \(pathA) — sizes would double-count"
                )
            }
        }
    }

    /// A wildcard in `path` would make the grant root unreadable without
    /// touching the disk, which is the whole reason the two fields are separate.
    @Test func pathsAreLiteralAndTildeRelative() {
        for entry in entries {
            let reason = PathPattern.rejectionReason(forPath: entry.path)
            #expect(reason == nil, "\(entry.id): \(entry.path) — \(reason ?? "")")
        }
    }

    @Test func subfoldersAreRelativeAndWellFormed() {
        for entry in entries {
            for subfolder in entry.subfolders {
                let reason = PathPattern.rejectionReason(forSubfolder: subfolder)
                #expect(reason == nil, "\(entry.id): \(subfolder) — \(reason ?? "")")
            }
        }
    }

    /// One path per entry means one grant root by construction. This checks the
    /// derivation still answers, rather than that the shape allows it.
    @Test func everyEntryDerivesAGrantRoot() {
        for entry in entries {
            #expect(entry.grantRoot != nil, "\(entry.id) has no grant root")
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
            // Where an app shares data with its own extensions — a share sheet,
            // a notification service. Telegram and WeChat keep their downloaded
            // media here rather than in Caches, because the extension has to
            // read it too.
            "Library/Group Containers",
            // pnpm puts its content-addressable store outside Caches.
            "Library/pnpm",
            // Device update images, still under the old iTunes folder.
            "Library/iTunes",
            // What apps reopen with; a folder of its own, not a cache.
            "Library/Saved Application State",
            // Go's module cache, at the root of GOPATH.
            "go",
            // conda distributions keep their package cache inside the install.
            "miniconda3",
            "anaconda3",
            "miniforge3",
            "mambaforge",
            // CapCut caches renders under the user's Movies folder.
            "Movies",
            // Installers and part-downloads collect where the browser puts them.
            "Downloads",
            // The Android SDK manager installs NDKs outside Application Support.
            "Library/Android",
        ]
        for entry in entries {
            guard let root = entry.grantRoot else { continue }
            #expect(
                allowed.contains(root) || root.hasPrefix("."),
                "\(entry.id) needs \(root): not an allowed Library folder or dot-directory"
            )
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

    /// Same rule for the sections' own glyphs, plus the one CI can check that a
    /// contributor cannot: that every section is named in the file at all.
    @Test func categorySymbolsResolve() throws {
        #if canImport(AppKit)
        for category in EasySweepCatalog.Category.allCases {
            let named = try #require(
                EasySweepCatalog.categorySymbols[category.rawValue],
                "\(category.rawValue): categories.json names no symbol"
            )
            #expect(
                NSImage(systemSymbolName: named, accessibilityDescription: nil) != nil,
                "\(category.rawValue): \(named) is not an SF Symbol on this OS"
            )
            #expect(category.symbol == named)
        }
        #endif
    }

    @Test func categoryNamesCoverSupportedLocales() {
        for category in EasySweepCatalog.Category.allCases {
            for identifier in supportedLocales {
                let name = category.localizedName(for: Locale(identifier: identifier))
                #expect(!name.isEmpty, "\(category.rawValue) has no name for \(identifier)")
                #expect(name != category.rawValue, "\(category.rawValue) fell back to its id for \(identifier)")
            }
        }
    }

    @Test func categoryNamesFallBackByLocaleParent() {
        #expect(
            EasySweepCatalog.Category.developer.localizedName(for: Locale(identifier: "fr-CA"))
                == "Développement"
        )
        #expect(
            EasySweepCatalog.Category.developer.localizedName(for: Locale(identifier: "zh-Hant-TW"))
                == "開發"
        )
        #expect(
            EasySweepCatalog.Category.developer.localizedName(for: Locale(identifier: "en-CA"))
                == "Developer"
        )
        #expect(
            EasySweepCatalog.Category.developer.localizedName(for: Locale(identifier: "xx"))
                == "Developer"
        )
    }

    @Test func entryCopyCoversSupportedLocales() {
        for entry in entries {
            for identifier in supportedLocales {
                let locale = Locale(identifier: identifier)
                let copy = entry.localizations[identifier]
                #expect(copy?.name?.isEmpty == false, "\(entry.id) has no name for \(identifier)")
                if identifier == "en" {
                    #expect(copy?.detail == nil || copy?.detail?.isEmpty == false)
                    #expect(entry.localizedDetail(for: locale) == entry.detail)
                } else {
                    #expect(copy?.detail?.isEmpty == false, "\(entry.id) has no detail for \(identifier)")
                    #expect(entry.localizedDetail(for: locale) == copy?.detail)
                }
                #expect(entry.localizedName(for: locale) == copy?.name)
            }
        }
    }

    @Test func entryCopyFallsBackByLocaleParent() throws {
        let entry = try #require(entries.first(where: { $0.id == "chrome-cache" }))
        #expect(
            entry.localizedName(for: Locale(identifier: "fr-CA"))
                == entry.localizations["fr"]?.name
        )
        #expect(
            entry.localizedDetail(for: Locale(identifier: "fr-CA"))
                == entry.localizations["fr"]?.detail
        )
        #expect(entry.localizedName(for: Locale(identifier: "xx")) == entry.name)
        #expect(entry.localizedDetail(for: Locale(identifier: "xx")) == entry.detail)
    }

    /// The built-in names are the fallback for a missing or unreadable file, so
    /// they have to be real too — nothing validates them at runtime.
    @Test func builtInCategorySymbolsResolve() {
        #if canImport(AppKit)
        for category in EasySweepCatalog.Category.allCases {
            #expect(
                NSImage(systemSymbolName: category.builtInSymbol, accessibilityDescription: nil) != nil,
                "\(category.rawValue): \(category.builtInSymbol) is not an SF Symbol on this OS"
            )
        }
        #endif
    }

    @Test func brandColoursParse() {
        for entry in entries {
            guard let hex = entry.color else { continue }
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

    /// One field owns the decision, and only its safest value cleans unasked.
    ///
    /// Written against `.safe` rather than against "not destructive", so a value
    /// added to `Risk` later has to be let in by someone rather than arriving
    /// already permitted.
    @Test func automaticCleaningIsDerivedFromRisk() {
        for entry in entries {
            #expect(entry.autoClean == (entry.risk == .safe))
        }
    }

    /// The 2.x Boolean is refused, and says what to write instead.
    ///
    /// A hard break: `true` meant both "comes back at a cost" and "does not come
    /// back", so there is no mapping this package could apply that would not be
    /// guessing at somebody's data.
    @Test func theOldBooleanIsRefusedWithAnExplanation() {
        for legacy in ["true", "false"] {
            let json = """
            {"id":"example","name":"Example","detail":"Rebuilt on use.",
             "path":"~/Library/Caches/example","risk":\(legacy)}
            """
            #expect(throws: DecodingError.self) {
                try JSONDecoder().decode(EasySweepCatalog.Entry.self, from: Data(json.utf8))
            }
        }
    }

    /// An unknown level is refused too, rather than falling back to the safest —
    /// which would be a newer catalogue quietly cleaning something unasked on an
    /// older build.
    @Test func anUnknownLevelIsRefused() {
        let json = """
        {"id":"example","name":"Example","detail":"Rebuilt on use.",
         "path":"~/Library/Caches/example","risk":"probably-fine"}
        """
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(EasySweepCatalog.Entry.self, from: Data(json.utf8))
        }
    }

    /// Every level is actually used. A value nobody assigns is one the UI offers
    /// an empty list for.
    @Test func everyLevelIsPopulated() {
        for level in EasySweepCatalog.Entry.Risk.allCases {
            #expect(entries.contains { $0.risk == level }, "no entry is \(level.rawValue)")
        }
    }

    private struct SafetyDeclaration: Decodable {
        let id: String
        let risk: EasySweepCatalog.Entry.Risk
    }

    /// There is no migration layer for the safety schema: every bundled record
    /// must carry the reviewed Boolean explicitly in JSON.
    @Test func everyBundledEntryDeclaresItsSafetyDecision() throws {
        for category in EasySweepCatalog.Category.allCases {
            let data = try #require(EasySweepCatalog.catalogData(in: category))
            _ = try JSONDecoder().decode([SafetyDeclaration].self, from: data)
        }
    }

    @Test func missingRiskIsRejected() {
        let base = """
        {"id":"example","name":"Example","detail":"Rebuilt on use.",
         "path":"~/Library/Caches/example"}
        """
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(EasySweepCatalog.Entry.self, from: Data(base.utf8))
        }
    }

    @Test func detailsStayUnderTenWords() {
        for entry in entries {
            #expect(
                entry.detail.split(whereSeparator: { $0.isWhitespace }).count < 10,
                "\(entry.id) English detail is too long"
            )
            for (locale, copy) in entry.localizations {
                guard let detail = copy.detail else { continue }
                #expect(
                    detail.split(whereSeparator: { $0.isWhitespace }).count < 10,
                    "\(entry.id) \(locale) detail is too long"
                )
            }
        }
    }

}

@Suite("Path patterns")
struct PathPatternTests {

    // MARK: - The entry's path

    @Test func literalPathsAreAccepted() {
        #expect(PathPattern.rejectionReason(forPath: "~/Library/Caches/Homebrew") == nil)
        #expect(PathPattern.rejectionReason(forPath: "~/.npm/_cacache") == nil)
    }

    @Test func absolutePathsAreRefused() {
        #expect(PathPattern.rejectionReason(forPath: "/Library/Caches") != nil)
        #expect(PathPattern.rejectionReason(forPath: "/etc/passwd") != nil)
    }

    /// A wildcard in the path would make the grant root unknowable without
    /// listing the disk, which is what splitting path from subfolders bought.
    @Test func aWildcardInThePathIsRefused() {
        #expect(PathPattern.rejectionReason(forPath: "~/Library/Caches/Google/Android*") != nil)
        #expect(PathPattern.rejectionReason(forPath: "~/*") != nil)
    }

    @Test func traversalIsRefusedInThePath() {
        #expect(PathPattern.rejectionReason(forPath: "~/Library/Caches/../../../etc") != nil)
    }

    // MARK: - Subfolders

    @Test func subfoldersMayCarryOneWildcardPerSegment() {
        #expect(PathPattern.rejectionReason(forSubfolder: "*") == nil)
        #expect(PathPattern.rejectionReason(forSubfolder: "*/Code Cache") == nil)
        #expect(PathPattern.rejectionReason(forSubfolder: "AndroidStudio*") == nil)
        #expect(PathPattern.rejectionReason(forSubfolder: "a*b*c") != nil)
    }

    @Test func recursiveGlobsAreNotRepresentable() {
        #expect(PathPattern.rejectionReason(forSubfolder: "**/tmp") != nil)
    }

    /// A subfolder that escapes its entry's path would put the grant root and
    /// the deletion target in different folders.
    @Test func subfoldersCannotEscapeTheirPath() {
        #expect(PathPattern.rejectionReason(forSubfolder: "../elsewhere") != nil)
        #expect(PathPattern.rejectionReason(forSubfolder: "/Library") != nil)
        #expect(PathPattern.rejectionReason(forSubfolder: "~/Library") != nil)
        #expect(PathPattern.rejectionReason(forSubfolder: "") != nil)
    }

    // MARK: - Matching

    @Test func matchingIsPrefixAndSuffix() {
        #expect(PathPattern.matches(name: "AndroidStudio2024.1", pattern: "AndroidStudio*"))
        #expect(!PathPattern.matches(name: "Chrome", pattern: "AndroidStudio*"))
        #expect(PathPattern.matches(name: "gradle-8.5-bin", pattern: "gradle-*-bin"))
        #expect(!PathPattern.matches(name: "gradle-8.5-all", pattern: "gradle-*-bin"))
    }

    // MARK: - Resolution

    /// No subfolders means the folder itself, and it resolves whether or not it
    /// exists — a caller needs the declared set to work out what to ask
    /// permission for.
    @Test func aBarePathResolvesToItself() {
        let home = URL(fileURLWithPath: "/nowhere-\(UUID().uuidString)")
        let resolved = PathPattern.resolve(path: "~/Library/Caches/Nothing", home: home)
        #expect(resolved.map(\.lastPathComponent) == ["Nothing"])
    }

    /// Named subfolders resolve in the order the entry lists them, and one that
    /// isn't there is simply absent — a tool installed differently should show
    /// fewer rows, not a broken entry.
    @Test func namedSubfoldersResolveInTheOrderGiven() throws {
        let root = try tree([".gradle/caches/x", ".gradle/wrapper/z"])
        defer { try? FileManager.default.removeItem(at: root) }

        let resolved = PathPattern.resolve(
            path: "~/.gradle", subfolders: ["caches", "daemon", "wrapper"], home: root
        )
        #expect(resolved.map(\.lastPathComponent) == ["caches", "wrapper"])
    }

    /// A wildcard segment must not match across a separator, or it would be a
    /// recursive glob wearing a different spelling.
    @Test func matchingDoesNotCrossSeparators() throws {
        let root = try tree([
            "Caches/Vendor/ToolA/nested/deep", "Caches/Vendor/Other/thing",
        ])
        defer { try? FileManager.default.removeItem(at: root) }

        let hits = PathPattern.resolve(
            path: "~/Caches/Vendor", subfolders: ["Tool*"], home: root
        )
        #expect(hits.count == 1)
        #expect(hits.first?.lastPathComponent == "ToolA")
    }

    /// Every child, one entry each — what `granular` used to mean.
    @Test func starResolvesToEveryChild() throws {
        let root = try tree(["DerivedData/App-abc/x", "DerivedData/Other-def/y"])
        defer { try? FileManager.default.removeItem(at: root) }

        let hits = PathPattern.resolve(path: "~/DerivedData", subfolders: ["*"], home: root)
        #expect(hits.map(\.lastPathComponent) == ["App-abc", "Other-def"])
    }

    /// A pattern one level down, expanded per match — the shape the Chromium
    /// browsers' per-profile caches need.
    @Test func aPatternResolvesPastACrowdedParent() throws {
        let root = try tree([
            "Chrome/Default/Service Worker/CacheStorage/a",
            "Chrome/Profile 1/Service Worker/CacheStorage/b",
            "Chrome/Local State",
        ])
        defer { try? FileManager.default.removeItem(at: root) }

        let hits = PathPattern.resolve(
            path: "~/Chrome", subfolders: ["*/Service Worker/CacheStorage"], home: root
        )
        #expect(hits.count == 2)
        #expect(hits.allSatisfy { $0.lastPathComponent == "CacheStorage" })
    }

    /// The cap must sit far beyond anything real. `~/Library/Logs/*` and
    /// `Application Support/*/Cache` run to hundreds on an ordinary Mac, and a
    /// truncated expansion is a partial measurement presented as a complete one.
    @Test func aRealisticExpansionIsNotTruncated() throws {
        #expect(PathPattern.resolutionLimit >= 4096)
        let names = (0..<900).map { "Support/app\($0)/Cache/x" }
        let root = try tree(names)
        defer { try? FileManager.default.removeItem(at: root) }

        let hits = PathPattern.resolve(path: "~/Support", subfolders: ["*/Cache"], home: root)
        #expect(hits.count == 900)
    }

    /// A wildcard skips hidden names, as a shell glob does. Enumerating
    /// `.DS_Store` and lock files as tickable rows offers something the entry
    /// did not mean to offer.
    @Test func aWildcardDoesNotMatchHiddenNames() throws {
        let root = try tree([
            "cache/real/x", "cache/.DS_Store", "cache/.lock/y", "cache/.pytest_cache/z",
        ])
        defer { try? FileManager.default.removeItem(at: root) }

        let all = PathPattern.resolve(path: "~/cache", subfolders: ["*"], home: root)
        #expect(all.map(\.lastPathComponent) == ["real"])

        // Unless the pattern asks for one by name.
        let hidden = PathPattern.resolve(path: "~/cache", subfolders: [".pytest*"], home: root)
        #expect(hidden.map(\.lastPathComponent) == [".pytest_cache"])
    }

    private func tree(_ files: [String]) throws -> URL {
        let fm = FileManager.default
        let root = fm.temporaryDirectory.appending(path: "PatternTests-\(UUID().uuidString)")
        for file in files {
            let url = root.appending(path: file)
            try fm.createDirectory(
                at: url.deletingLastPathComponent(), withIntermediateDirectories: true
            )
            try Data().write(to: url)
        }
        return root
    }
}
