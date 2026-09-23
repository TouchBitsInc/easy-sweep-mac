import Foundation

/// Folders a section finds at runtime, beside the entries it lists.
///
/// Every entry names a folder someone reviewed. `~/Library/Caches` holds one
/// folder per installed application, and no list of entries keeps up with what
/// a particular Mac has installed. So a section may declare a *discovery root*
/// in `categories.json`: a folder whose children become rows when — and only
/// when — a rule this package states says whose they are.
///
/// The package still never touches the disk. A consumer lists the root and
/// passes the names in; `discoveredFolders` answers with the ones the rule
/// accepts and no entry already claims. That keeps the root, the rule and the
/// exclusions in this repository, under the same review as every path, and
/// keeps a discovered folder from being counted twice.
extension EasySweepCatalog {

    /// One folder a section discovers inside, declared as `discovers` in
    /// `categories.json`.
    public struct DiscoveryRoot: Decodable, Hashable, Sendable {

        /// How a child of the root is recognised as belonging to something.
        public enum Match: String, Decodable, Sendable {
            /// The child's name is the bundle identifier of an installed
            /// application. Nothing else is accepted: a folder that names no
            /// installed app is not offered, however cache-like it looks.
            case bundleIdentifier
        }

        /// A literal, tilde-relative folder — the same rule as `Entry.path`.
        public let path: String

        public let match: Match

        /// The level every discovered folder carries. Validation refuses
        /// `safe`: a folder nobody reviewed must never be cleaned unattended.
        public let risk: Entry.Risk
    }

    /// A child of a discovery root that the rule accepted.
    public struct DiscoveredFolder: Hashable, Sendable {
        /// Tilde-relative, like `Entry.path`.
        public let path: String
        /// The folder's own name — the last part of `path`. Unique within a
        /// root, where `bundleIdentifier` is not: one app may own several.
        public let name: String
        /// The installed application the folder belongs to.
        public let bundleIdentifier: String
        public let root: DiscoveryRoot
    }

    /// The roots one section discovers in. Empty for a section that lists
    /// entries only, which is every section but App Data.
    public static func discoveryRoots(in category: Category) -> [DiscoveryRoot] {
        categoryDiscoveryRoots[category.rawValue] ?? []
    }

    /// Which of a root's children are offered.
    ///
    /// - `names` is the root's directory listing, as the consumer read it.
    /// - `installedBundleIdentifiers` is what the consumer knows to be
    ///   installed. The package cannot see `/Applications`; the consumer
    ///   decides what counts, and is expected to leave system apps out.
    ///
    /// A name is accepted when it is an installed bundle identifier, or
    /// becomes one after dropping trailing dot-separated parts — so
    /// `com.example.app.helper` belongs to `com.example.app`. Trimming stops
    /// at two parts, and still needs an exact match: `com.example` owns
    /// nothing unless an app is literally called that. It must also not be
    /// hidden, is not Apple's (`com.apple.*` folders belong to the
    /// system, and clearing some of them costs a sign-in or a reboot), and
    /// neither equals, contains nor sits inside any folder an entry declares.
    /// The last rule is the same containment `noPathContainsAnother` enforces
    /// between entries, applied on declared paths with wildcards honoured, so
    /// a folder the catalog lists under its own name is never offered twice.
    public static func discoveredFolders(
        under root: DiscoveryRoot,
        names: [String],
        installedBundleIdentifiers: Set<String>
    ) -> [DiscoveredFolder] {
        let claimed = all.flatMap(\.declaredPaths).map(segments)
        return names.sorted().compactMap { name in
            guard !name.hasPrefix("."),
                  !name.hasPrefix("com.apple."),
                  !name.contains("/"),
                  let owner = owner(of: name, among: installedBundleIdentifiers)
            else { return nil }
            let path = "\(root.path)/\(name)"
            let candidate = segments(path)
            guard !claimed.contains(where: { overlaps($0, candidate) }) else { return nil }
            return DiscoveredFolder(path: path, name: name, bundleIdentifier: owner, root: root)
        }
    }

    /// The installed identifier a folder name belongs to: the name itself, or
    /// the longest prefix of it, cut at a dot, of at least two parts.
    static func owner(of name: String, among installed: Set<String>) -> String? {
        var parts = name.split(separator: ".", omittingEmptySubsequences: false)
        while parts.count >= 2 {
            let candidate = parts.joined(separator: ".")
            if installed.contains(candidate) { return candidate }
            if parts.count == 2 { break }
            parts.removeLast()
        }
        return installed.contains(name) ? name : nil
    }

    private static func segments(_ path: String) -> [String] {
        path.split(separator: "/").map(String.init)
    }

    /// Whether one declared path is the other, contains it, or sits inside it.
    /// Segment by segment, with a declared wildcard matched the way
    /// `PathPattern` resolves it.
    private static func overlaps(_ declared: [String], _ candidate: [String]) -> Bool {
        for (pattern, name) in zip(declared, candidate)
        where !PathPattern.matches(name: name, pattern: pattern) {
            return false
        }
        return true
    }
}
