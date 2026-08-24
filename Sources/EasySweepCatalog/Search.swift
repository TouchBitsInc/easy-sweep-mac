import Foundation

extension EasySweepCatalog {

    /// Something worth cleaning that is *found* rather than known.
    ///
    /// An `Entry` names a path and the app deletes it. A rule names what a match
    /// looks like, and the app has to go and look — `node_modules`, but only
    /// beside a `package.json`, and only under a folder somebody pointed it at.
    /// Published here for the same reason the entries are: knowing that
    /// `_build` regenerates from `mix.exs` is long-tail knowledge, and someone
    /// writing Elixir knows it better than we do.
    ///
    /// A contributed rule cannot widen what gets searched. Depth is bounded, a
    /// directory name needs a marker file beside it, roots are literal tilde
    /// paths, and the consuming app trashes rather than deletes. A rule is
    /// reviewable by reading it, which is the property a descending glob would
    /// destroy.
    public struct SearchRule: Codable, Identifiable, Hashable, Sendable {

        /// How the root is walked. The two kinds of find want genuinely
        /// different scans, so a rule says which it needs rather than the app
        /// inferring it from the fields that happen to be filled in.
        public enum Engine: String, Codable, Sendable {
            /// Recursive to `depth`, matching directories, stopping at each
            /// match instead of descending into it. For a tree of projects.
            case tree
            /// One listing of each root's own children, matching files. For a
            /// downloads folder — something filed away in a subfolder there is
            /// being kept, not forgotten.
            case flat
        }

        /// Stable and permanent, like an entry's. Keys whatever the consuming
        /// app records against it.
        public let id: String
        public let name: String
        /// What someone reads immediately before deleting: what regenerates it,
        /// and what that costs.
        public let detail: String
        /// Absent means `risky`, the same conservative default the entries take.
        public let risk: Risk
        /// An SF Symbol. Absent leaves the choice to the app, which is safer
        /// than a wrong name — an unknown symbol renders as nothing at all.
        public let symbol: String?

        public let engine: Engine

        /// Where to look, tilde-relative and literal — one path, like an entry.
        ///
        /// **Nil means the user says where**, which is the normal case for
        /// `tree`: nobody's project folder is at a path this package could know,
        /// and shipping `~/Projects` would be a guess dressed as knowledge. Only
        /// locations macOS itself defines — `~/Downloads`, `~/Desktop` — are
        /// named here, and a rule that applies to both is two rules, because one
        /// path per rule is the invariant that makes a grant root readable.
        /// Rules sharing a `name` are one group on screen.
        public let path: String?

        /// How far below a root to look, for `tree`. Bounded by the consumer;
        /// this is what keeps a mistyped root from running for hours.
        public let depth: Int

        /// Directory names, for `tree`.
        public let names: [String]
        /// A directory matches only when one of these sits beside it.
        ///
        /// The whole guard: `target` is a Rust build next to a `Cargo.toml` and
        /// somebody's folder anywhere else. Empty is allowed but has to be
        /// earned by a name that means nothing else, like `__pycache__`.
        public let besideAnyOf: [String]

        /// File extensions, lowercase and without the dot, for `flat`.
        public let extensions: [String]
        /// How long a file must have sat untouched before it is offered. Nil
        /// means immediately, which is right only for something nothing can
        /// open — a half-finished download.
        public let minimumAgeDays: Int?

        public init(
            id: String,
            name: String,
            detail: String,
            engine: Engine,
            risk: Risk = .risky,
            symbol: String? = nil,
            path: String? = nil,
            depth: Int = 1,
            names: [String] = [],
            besideAnyOf: [String] = [],
            extensions: [String] = [],
            minimumAgeDays: Int? = nil
        ) {
            self.id = id
            self.name = name
            self.detail = detail
            self.engine = engine
            self.risk = risk
            self.symbol = symbol
            self.path = path
            self.depth = depth
            self.names = names
            self.besideAnyOf = besideAnyOf
            self.extensions = extensions
            self.minimumAgeDays = minimumAgeDays
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(String.self, forKey: .id)
            name = try container.decode(String.self, forKey: .name)
            detail = try container.decode(String.self, forKey: .detail)
            engine = try container.decode(Engine.self, forKey: .engine)
            // Everything below defaults, so an older build reading a newer
            // catalog degrades rather than dropping the rule.
            risk = try container.decodeIfPresent(Risk.self, forKey: .risk) ?? .risky
            symbol = try container.decodeIfPresent(String.self, forKey: .symbol)
            path = try container.decodeIfPresent(String.self, forKey: .path)
            depth = try container.decodeIfPresent(Int.self, forKey: .depth) ?? 1
            names = try container.decodeIfPresent([String].self, forKey: .names) ?? []
            besideAnyOf =
                try container.decodeIfPresent([String].self, forKey: .besideAnyOf) ?? []
            extensions = try container.decodeIfPresent([String].self, forKey: .extensions) ?? []
            minimumAgeDays = try container.decodeIfPresent(Int.self, forKey: .minimumAgeDays)
        }

        // MARK: - Matching

        /// Whether a directory of this name matches, given what sits beside it.
        /// Pure: the caller does the listing, this only decides.
        public func matches(directory: String, siblings: Set<String>) -> Bool {
            guard engine == .tree, names.contains(directory) else { return false }
            return besideAnyOf.isEmpty || besideAnyOf.contains(where: siblings.contains)
        }

        /// Whether a file matches, given its lowercased extension and how long
        /// it has sat untouched. An unknown age is unproven, and unproven is not
        /// offered.
        public func matches(extension ext: String, age: TimeInterval?) -> Bool {
            guard engine == .flat, extensions.contains(ext) else { return false }
            guard let minimumAgeDays else { return true }
            guard let age else { return false }
            return age > Double(minimumAgeDays) * 24 * 60 * 60
        }
    }

    /// Every search rule.
    ///
    /// Decoded per rule, skipping any that fail — one malformed record must not
    /// leave the consuming app searching for nothing, the same argument the
    /// entries make.
    public static let searchRules: [SearchRule] = {
        guard let url = Bundle.module.url(
            forResource: "discover", withExtension: "json", subdirectory: "Catalog"
        ), let data = try? Data(contentsOf: url) else {
            return []
        }
        let decoded = (try? JSONDecoder().decode([SkippingBadRule].self, from: data)) ?? []
        return decoded.compactMap(\.rule)
    }()

    private struct SkippingBadRule: Decodable {
        let rule: SearchRule?

        init(from decoder: any Decoder) throws {
            rule = try? SearchRule(from: decoder)
        }
    }
}
