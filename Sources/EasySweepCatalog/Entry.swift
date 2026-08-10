import Foundation

// Nested in the namespace rather than named `CatalogEntry` and friends: the
// module is already called EasySweepCatalog, so a prefix only repeats it, and
// bare `Entry` at a use site says nothing. `EasySweepCatalog.Entry` reads.
extension EasySweepCatalog {

    /// Which section an entry appears under.
    ///
    /// A reading order, not a permission boundary — the four sections span 29
    /// grant roots between them. See `Entry.grantRoots`.
    public enum Category: String, Codable, CaseIterable, Sendable {
        case developer
        case aiTools
        case browsers
        case multimedia
    }

    /// How much a user stands to lose by cleaning an entry.
    public enum Risk: String, Codable, Sendable {
        /// Regenerated automatically; deleting costs only rebuild or re-download time.
        case safe
        /// Contains something that cannot be recreated, or whose loss is disruptive.
        case risky
    }

    /// One cleanable location, as published in the catalog.
    ///
    /// Deliberately *not* the whole of what the app knows about a target. Two
    /// fields are absent because a contributed file must not be able to set
    /// them:
    ///
    /// - whether the one-click clean may take this without the user ticking
    ///   anything, and
    /// - whether removal has to go through a tool such as `simctl` rather than
    ///   the filesystem.
    ///
    /// Both live in the consuming app, keyed by `id`. A pull request here can
    /// add a location; it cannot widen what gets deleted automatically.
    public struct Entry: Codable, Identifiable, Hashable, Sendable {
        /// Stable and permanent. Keys the consuming app's own table of settings,
        /// so renaming one silently drops whatever that app had recorded
        /// against it.
        public let id: String
        public let name: String
        /// What the user reads immediately before deleting. States what
        /// regenerates the files and how — never "safe to delete", which `risk`
        /// already carries.
        public let detail: String
        /// Tilde-relative, e.g. `~/Library/Caches/Homebrew`. May contain a
        /// single `*` within one path segment; see `PathPattern`.
        public let paths: [String]
        /// Absent means `risky`. Silence is conservative: an entry nobody has
        /// classified should read as the more cautious of the two.
        public let risk: Risk
        /// Whether to enumerate one level of children so the user can pick
        /// individual versions, projects or devices.
        public let granular: Bool
        /// An SF Symbol name. Absent falls back to the category's own symbol —
        /// which is safer than a wrong name, because an unknown symbol renders
        /// as nothing at all rather than a placeholder.
        public let symbol: String?
        /// The brand hex exactly as the project publishes it, e.g. `#CB3837`.
        /// Unadjusted — lifting a near-black value for legibility is the
        /// consuming app's business, and doing it here would misreport the
        /// brand.
        public let brandColor: String?

        public init(
            id: String,
            name: String,
            detail: String,
            paths: [String],
            risk: Risk = .risky,
            granular: Bool = false,
            symbol: String? = nil,
            brandColor: String? = nil
        ) {
            self.id = id
            self.name = name
            self.detail = detail
            self.paths = paths
            self.risk = risk
            self.granular = granular
            self.symbol = symbol
            self.brandColor = brandColor
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(String.self, forKey: .id)
            name = try container.decode(String.self, forKey: .name)
            detail = try container.decode(String.self, forKey: .detail)
            paths = try container.decode([String].self, forKey: .paths)
            // Both default rather than being required, so an older build
            // reading a newer catalog degrades instead of failing.
            risk = try container.decodeIfPresent(Risk.self, forKey: .risk) ?? .risky
            granular = try container.decodeIfPresent(Bool.self, forKey: .granular) ?? false
            symbol = try container.decodeIfPresent(String.self, forKey: .symbol)
            brandColor = try container.decodeIfPresent(String.self, forKey: .brandColor)
        }
    }
}

extension EasySweepCatalog.Entry {
    /// The folder a sandboxed app must be granted to reach this entry, relative
    /// to the home directory — `Library/Caches`, `.npm`, `Library/Developer`.
    ///
    /// Derived rather than declared, so it cannot disagree with `paths`.
    /// `Library` alone is far too broad to ask for, so paths under it descend
    /// one level; a bare dot-directory in `~` is already narrow enough.
    ///
    /// Every entry resolves to exactly one. An entry spanning two would be half
    /// usable under the sandbox, with no honest way to show that on one row.
    public var grantRoots: Set<String> {
        Set(paths.compactMap(Self.grantRoot(of:)))
    }

    /// The one folder a sandboxed app would have to be granted to reach `path`.
    ///
    /// Public because a consumer needs it for paths that aren't in the catalog
    /// — ones the user picked, or ones a test builds by hand — and answering it
    /// the same way as the catalog does is the whole point. It reads the
    /// pattern only, never the disk, which is why a wildcard may not appear in
    /// the first two segments.
    public static func grantRoot(of path: String) -> String? {
        let parts = path.hasPrefix("~/")
            ? path.dropFirst(2).split(separator: "/").map(String.init)
            : []
        guard let first = parts.first else { return nil }
        if first == "Library" {
            guard parts.count > 1 else { return nil }
            return "Library/\(parts[1])"
        }
        return first
    }
}
