import Foundation

// Nested in the namespace rather than named `CatalogEntry` and friends: the
// module is already called EasySweepCatalog, so a prefix only repeats it, and
// bare `Entry` at a use site says nothing. `EasySweepCatalog.Entry` reads.
extension EasySweepCatalog {

    /// Which section an entry appears under.
    ///
    /// A reading order, not a permission boundary — the sections span dozens of
    /// grant roots between them. See `Entry.grantRoot`.
    ///
    /// **The case order is the display order.** `allCases` is the sequence a
    /// consumer shows its sections in, and this enum is the only place it is
    /// published, so moving a case here moves the section.
    public enum Category: String, Codable, CaseIterable, Sendable {
        /// macOS's own regenerable data, and the caches of apps that fit none of
        /// the tool sections below. Deliberately one section rather than two: an
        /// app's cache and the system's are the same kind of thing to a user
        /// clearing space, and `risk` is what separates a wallpaper that
        /// re-downloads from a chat cache holding received media.
        ///
        /// First, because it is the one section on every Mac. The rest describe
        /// an installed toolchain.
        case system
        case developer
        case aiTools
        case browsers
        case messaging
        case multimedia

        /// Whether the section leads the list and stays there.
        ///
        /// Pinned means every Mac has it, whatever is installed — so it is not a
        /// section anyone opts out of, and a consumer should not offer to put it
        /// away. Everything else describes installed tooling, which a given Mac
        /// may have no use for.
        ///
        /// Published beside the order, and for the same reason: where a section
        /// sits is a property of what the section *is*. It says nothing about
        /// what may be deleted.
        ///
        /// Exhaustive on purpose. A section added later has to decide.
        public var isPinned: Bool {
            switch self {
            case .system: true
            case .developer, .aiTools, .browsers, .messaging, .multimedia: false
            }
        }

        /// The pinned sections, in order, and everything else in order.
        ///
        /// Two lists because the kinds are not interchangeable, and a consumer
        /// laying out a sidebar needs them apart rather than filtered at each
        /// use site.
        public static let pinned: [Category] = allCases.filter(\.isPinned)
        public static let unpinned: [Category] = allCases.filter { !$0.isPinned }
    }

    /// User-facing entry copy keyed by a BCP-47 locale identifier.
    public struct LocalizedContent: Codable, Hashable, Sendable {
        public let name: String?
        public let detail: String?

        public init(name: String? = nil, detail: String? = nil) {
            self.name = name
            self.detail = detail
        }
    }

    /// One cleanable location, as published in the catalog.
    ///
    /// **One path, and either the folder itself or what to take inside it.** A
    /// multi-path entry used to be possible, which meant an entry could span two
    /// folders a sandboxed consumer has to be granted separately — half-usable,
    /// with no honest way to show that on one row. Now the shape says it: one
    /// literal `path`, so the grant root is the path, and `subfolders` for
    /// anything narrower.
    ///
    /// `risk` is the single cleaning decision. `true` requires confirmation;
    /// `false` permits automatic cleaning. Every entry must declare it.
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
        /// Tilde-relative and **literal** — no wildcard, so the folder a
        /// sandboxed consumer must be granted can be read straight off it.
        public let path: String
        /// What to take inside `path`, as patterns relative to it.
        ///
        /// - **Empty** means the folder itself is the target, one row.
        /// - **`["*"]`** means every child, a row each — what `granular` meant.
        /// - **A list** names children, a row each. A single `*` may appear in
        ///   any segment (`*/Code Cache`), because `path` already supplies the
        ///   literal anchor.
        ///
        /// Subfolders are *rows*: whatever is listed here is what the user ticks.
        public let subfolders: [String]
        /// Whether cleaning requires manual confirmation.
        public let risk: Bool
        /// No risk means automatic cleaning; risky entries always require review.
        public var autoClean: Bool { !risk }
        /// An SF Symbol name. Absent falls back to the category's own symbol —
        /// which is safer than a wrong name, because an unknown symbol renders
        /// as nothing at all rather than a placeholder.
        public let symbol: String?
        /// The brand hex exactly as the project publishes it, e.g. `#CB3837`.
        /// Unadjusted — lifting a near-black value for legibility is the
        /// consuming app's business, and doing it here would misreport the
        /// brand.
        public let color: String?
        /// Localized name and explanation. English remains in `name` and
        /// `detail` so older consumers can read newer catalog files.
        public let localizations: [String: LocalizedContent]

        public init(
            id: String,
            name: String,
            detail: String,
            path: String,
            subfolders: [String] = [],
            risk: Bool,
            symbol: String? = nil,
            color: String? = nil,
            localizations: [String: LocalizedContent] = [:]
        ) {
            self.id = id
            self.name = name
            self.detail = detail
            self.path = path
            self.subfolders = subfolders
            self.risk = risk
            self.symbol = symbol
            self.color = color
            self.localizations = localizations
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(String.self, forKey: .id)
            name = try container.decode(String.self, forKey: .name)
            detail = try container.decode(String.self, forKey: .detail)
            path = try container.decode(String.self, forKey: .path)
            subfolders = try container.decodeIfPresent([String].self, forKey: .subfolders) ?? []
            risk = try container.decode(Bool.self, forKey: .risk)
            symbol = try container.decodeIfPresent(String.self, forKey: .symbol)
            color = try container.decodeIfPresent(String.self, forKey: .color)
            localizations = try container.decodeIfPresent(
                [String: LocalizedContent].self,
                forKey: .localizations
            ) ?? [:]
        }

        /// The entry name for a locale, falling back to the English field.
        public func localizedName(for locale: Locale = .current) -> String {
            CatalogLocalization.resolve(localizations, locale: locale) { $0.name } ?? name
        }

        /// The entry explanation for a locale, falling back to the English field.
        public func localizedDetail(for locale: Locale = .current) -> String {
            CatalogLocalization.resolve(localizations, locale: locale) { $0.detail } ?? detail
        }

        /// Whether the user picks among children rather than taking the whole
        /// folder. What `granular` used to say, now derived from the shape.
        public var isGranular: Bool { !subfolders.isEmpty }
    }
}

extension EasySweepCatalog.Entry {
    /// The folder a sandboxed app must be granted to reach this entry, relative
    /// to the home directory — `Library/Caches`, `.npm`, `Library/Developer`.
    ///
    /// Derived from `path`, which is literal, so it never touches the disk.
    /// `Library` alone is far too broad to ask for, so paths under it descend
    /// one level; a bare dot-directory in `~` is already narrow enough.
    ///
    /// One per entry, by construction now rather than by a test — that is what
    /// the single `path` bought.
    public var grantRoot: String? {
        Self.grantRoot(of: path)
    }

    /// The one folder a sandboxed app would have to be granted to reach `path`.
    ///
    /// Public because a consumer needs it for paths that aren't in the catalog
    /// — ones the user picked, or ones a test builds by hand — and answering it
    /// the same way as the catalog does is the whole point.
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
