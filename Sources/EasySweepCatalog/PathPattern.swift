import Foundation

/// Turns an entry's `path` and `subfolders` into the folders on disk it names.
///
/// The split is the safety property. `path` is literal, so the folder a
/// sandboxed consumer has to be granted is readable without touching the disk;
/// `subfolders` may hold a wildcard, because whatever it matches is already
/// under a folder the entry named in full.
///
/// The limits are the point:
///
/// - `*` matches **within one path segment**. `**` is not representable, so a
///   pattern can never descend on its own.
/// - `path` carries no wildcard at all, and no `..` appears anywhere.
/// - Expansion is capped, to stop unbounded work rather than to second-guess a
///   plausible entry.
public enum PathPattern {
    /// How many folders one entry may resolve to.
    ///
    /// Generous rather than tight: `~/Library/Application Support/*/Code Cache`
    /// is bounded by how many apps are installed, which is legitimately in the
    /// hundreds, and a cap that truncated it would report a partial measurement
    /// as a complete one.
    public static let resolutionLimit = 512

    /// Whether a catalog path contains the wildcard.
    public static func isPattern(_ path: String) -> Bool {
        path.contains("*")
    }

    /// Validation of an entry's `path`, shared by CI and by anything loading the
    /// catalog.
    ///
    /// Returns nil when the path is acceptable, or a sentence naming what is
    /// wrong with it.
    public static func rejectionReason(forPath path: String) -> String? {
        guard path.hasPrefix("~/") else {
            return "must start with ~/ — absolute paths are not accepted"
        }
        if path.contains("..") {
            return "must not contain .."
        }
        if path.contains("*") {
            return "must be literal — a wildcard belongs in subfolders, so the "
                + "grant root can be read without touching the disk"
        }
        guard !path.dropFirst(2).split(separator: "/").isEmpty else {
            return "names no location"
        }
        return nil
    }

    /// Validation of one `subfolders` pattern, relative to an entry's path.
    public static func rejectionReason(forSubfolder subfolder: String) -> String? {
        if subfolder.isEmpty { return "is empty" }
        if subfolder.hasPrefix("/") || subfolder.hasPrefix("~") {
            return "must be relative to the entry's path"
        }
        if subfolder.contains("..") { return "must not contain .." }
        if subfolder.contains("**") {
            return "** is not supported; * matches within one segment only"
        }
        for segment in subfolder.split(separator: "/") where segment.contains("*") {
            if segment.filter({ $0 == "*" }).count > 1 {
                return "more than one * in \"\(segment)\""
            }
        }
        return nil
    }

    // MARK: - Resolution

    /// The concrete folders an entry names.
    ///
    /// With no subfolders the answer is the path itself, **whether or not it
    /// exists**: a caller needs the declared set to work out what folder access
    /// it would have to ask for, and filtering here would make a tool that isn't
    /// installed look like a tool that needs no permission.
    ///
    /// With subfolders, each pattern is expanded against the disk, so what comes
    /// back necessarily exists — a listing can only report what is there.
    public static func resolve(
        path: String,
        subfolders: [String] = [],
        home: URL
    ) -> [URL] {
        guard rejectionReason(forPath: path) == nil else { return [] }
        let root = home.appending(path: String(path.dropFirst(2)))
        guard !subfolders.isEmpty else { return [root] }

        var resolved: [URL] = []
        for subfolder in subfolders {
            guard rejectionReason(forSubfolder: subfolder) == nil else { continue }
            resolved += expand(subfolder, under: root)
            if resolved.count >= resolutionLimit {
                return Array(resolved.prefix(resolutionLimit))
            }
        }
        return resolved
    }

    /// One pattern, expanded segment by segment.
    ///
    /// Literal segments are appended; a wildcard segment is matched against a
    /// directory listing. Nothing is ever globbed across a separator, so the
    /// number of listings is bounded by the wildcard segments the pattern was
    /// allowed to carry.
    private static func expand(_ subfolder: String, under root: URL) -> [URL] {
        let fileManager = FileManager.default
        var candidates = [root]

        for segment in subfolder.split(separator: "/").map(String.init) {
            guard isPattern(segment) else {
                candidates = candidates.map { $0.appending(path: segment) }
                continue
            }
            candidates = candidates.flatMap { parent -> [URL] in
                let names = (try? fileManager.contentsOfDirectory(atPath: parent.path)) ?? []
                return names
                    .filter { matches(name: $0, pattern: segment) }
                    .sorted()
                    .map { parent.appending(path: $0) }
            }
            if candidates.count > resolutionLimit {
                candidates = Array(candidates.prefix(resolutionLimit))
            }
        }

        return candidates.filter { fileManager.fileExists(atPath: $0.path) }
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

extension EasySweepCatalog.Entry {
    /// Every folder this entry names, expanded against the disk.
    public func resolved(home: URL) -> [URL] {
        PathPattern.resolve(path: path, subfolders: subfolders, home: home)
    }

    /// What the entry declares, without touching the disk: the path itself, and
    /// each subfolder pattern joined to it.
    ///
    /// This is what a containment check compares — two entries must not be able
    /// to name the same folder, and asking the disk would make that answer
    /// depend on which machine the test ran on.
    public var declaredPaths: [String] {
        guard !subfolders.isEmpty else { return [path] }
        return subfolders.map { "\(path)/\($0)" }
    }
}
