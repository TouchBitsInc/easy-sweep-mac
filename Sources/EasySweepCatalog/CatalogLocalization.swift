import Foundation

/// Locale matching shared by category and entry presentation data.
enum CatalogLocalization {

    static func resolve<Value>(
        _ values: [String: Value],
        locale: Locale,
        value: (Value) -> String?
    ) -> String? {
        let normalized = locale.identifier.replacingOccurrences(of: "_", with: "-")
        let components = normalized.split(separator: "-").map(String.init)
        var candidates = [normalized]

        if let language = components.first {
            if let script = components.first(where: { $0.count == 4 }) {
                candidates.append("\(language)-\(script)")
            }
            if let region = components.dropFirst().first(where: { $0.count == 2 || $0.count == 3 }) {
                candidates.append("\(language)-\(region)")
            }
            candidates.append(language)
        }
        candidates.append("en")

        for candidate in candidates {
            if let match = values.first(where: {
                $0.key.compare(candidate, options: .caseInsensitive) == .orderedSame
            }), let resolved = value(match.value), !resolved.isEmpty {
                return resolved
            }
        }
        return nil
    }
}
