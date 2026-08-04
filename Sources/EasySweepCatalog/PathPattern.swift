import Foundation

/// Expands the catalog's tilde paths, including the one wildcard form it allows.
///
/// Most versioned locations need no pattern at all. Where the version *is* the
/// whole leaf — `iOS DeviceSupport/iPhone17,4 26.5.2 (23F84)` — the entry names
/// the parent and sets `granular`, and the consuming app enumerates. That gives
/// a size and a tickable row per version, which a wildcard cannot.
///
/// A pattern is for the other shape: a versioned name sitting among unrelated
/// siblings. `~/Library/Caches/Google` holds Chrome and Chrome Beta as well as
/// Android Studio, so naming the parent would sweep a browser's cache, and
/// naming the exact folder breaks at the next upgrade.
///
/// The limits are the point:
///
/// - `*` matches **within one path segment**. `**` is not representable, so a
///   pattern can never descend on its own.
/// - No wildcard in the first two segments. Every pattern keeps a literal
///   anchor, `~/*` is refused, and `grantRoots` stays computable without
///   touching the disk.
/// - Matches are capped. A pattern resolving to hundreds of directories is a
///   bug or an attack, not a cache.
public enum PathPattern {
    /// How many matches one pattern may produce before it is treated as wrong.
    public static let matchLimit = 32

    /// Whether a catalog path contains the wildcard.
    public static func isPattern(_ path: String) -> Bool {
        path.contains("*")
    }

    /// Validation, shared by CI and by anything loading the catalog.
    ///
    /// Returns nil when the path is acceptable, or a sentence naming what is
    /// wrong with it.
    public static func rejectionReason(for path: String) -> String? {
        guard path.hasPrefix("~/") else {
            return "must start with ~/ — absolute paths are not accepted"
        }
        if path.contains("..") {
            return "must not contain .."
        }
        if path.contains("**") {
            return "** is not supported; * matches within one segment only"
        }

        let segments = path.dropFirst(2).split(separator: "/").map(String.init)
        guard !segments.isEmpty else { return "names no location" }

        for (index, segment) in segments.enumerated() where segment.contains("*") {
            if index < 2 {
                return "wildcard in segment \(index + 1) (\"\(segment)\") — the "
                    + "first two segments must be literal so the grant root is known"
            }
            if segment.filter({ $0 == "*" }).count > 1 {
                return "more than one * in \"\(segment)\""
            }
        }
        return nil
    }

    /// The concrete locations a catalog path names.
    ///
    /// A literal yields itself, **whether or not it exists**. That matters: a
    /// caller needs the declared set to work out what folder access it would
    /// have to ask for, and filtering here would make a tool that isn't
    /// installed look like a tool that needs no permission. Deciding what is
    /// present is a separate question, asked separately.
    ///
    /// A pattern is resolved by listing its literal parent and matching the one
    /// wildcard segment, so nothing is ever globbed across a separator. Those
    /// results necessarily exist, because they came from a directory listing.
    public static func resolve(_ path: String, home: URL) -> [URL] {
        let fileManager = FileManager.default
        guard rejectionReason(for: path) == nil else { return [] }

        let relative = String(path.dropFirst(2))
        guard isPattern(path) else {
            return [home.appending(path: relative)]
        }

        let segments = relative.split(separator: "/").map(String.init)
        guard let wildcardIndex = segments.firstIndex(where: { $0.contains("*") }) else {
            return []
        }
        let pattern = segments[wildcardIndex]
        let parent = home.appending(path: segments[..<wildcardIndex].joined(separator: "/"))
        let remainder = segments[(wildcardIndex + 1)...].joined(separator: "/")

        let names = (try? fileManager.contentsOfDirectory(atPath: parent.path)) ?? []
        var resolved = names
            .filter { matches(name: $0, pattern: pattern) }
            .sorted()
            .prefix(matchLimit)
            .map { parent.appending(path: $0) }

        if !remainder.isEmpty {
            resolved = resolved.map { $0.appending(path: remainder) }
        }
        return resolved.filter { fileManager.fileExists(atPath: $0.path) }
    }

    /// One `*` within a single segment, so this is a prefix and suffix test
    /// rather than a glob engine.
    static func matches(name: String, pattern: String) -> Bool {
        guard let star = pattern.firstIndex(of: "*") else { return name == pattern }
        let prefix = String(pattern[pattern.startIndex..<star])
        let suffix = String(pattern[pattern.index(after: star)...])
        guard name.count >= prefix.count + suffix.count else { return false }
        return name.hasPrefix(prefix) && name.hasSuffix(suffix)
    }
}
