import AppKit

extension EasySweepCatalog.Category {

    /// The section title for a locale, falling back through a regional/script
    /// match, the language, and finally English. The config uses BCP-47 keys,
    /// so adding another locale is data-only.
    public func localizedName(for locale: Locale = .current) -> String {
        EasySweepCatalog.categoryPresentations[rawValue]?.name(for: locale)
            ?? rawValue
    }

    /// The SF Symbol a consumer draws for the section, from `categories.json`.
    ///
    /// Contributable for the same reason `Entry.symbol` is: which glyph reads as
    /// "media" is exactly the long-tail judgement this repository exists to
    /// collect, and a section's icon is the fallback for every entry under it.
    /// It says nothing about what may be deleted.
    ///
    /// Validated before it is returned. An SF Symbol name that doesn't resolve
    /// renders as *nothing at all* rather than a placeholder, so a typo here
    /// would blank a section's row with no error anywhere — and a name valid on
    /// one macOS release may not exist on an older one, which no CI check on
    /// this repository can see.
    public var symbol: String {
        guard let named = EasySweepCatalog.categorySymbols[rawValue],
              NSImage(systemSymbolName: named, accessibilityDescription: nil) != nil
        else { return builtInSymbol }
        return named
    }

    /// What ships in the binary, used when the data file names no symbol for
    /// this section or names one this macOS doesn't have.
    ///
    /// Exhaustive on purpose: a section added later has to choose its own
    /// rather than inherit a placeholder.
    public var builtInSymbol: String {
        switch self {
        case .system: "laptopcomputer"
        case .developer: "hammer"
        // "globe" rather than "safari": the section covers six browsers, and
        // naming it after one of them reads as being about that one.
        case .browsers: "globe"
        case .aiTools: "sparkles"
        // A clapperboard rather than a palette: the section's largest items are
        // video editors' caches and renders, where a palette read as drawing.
        case .multimedia: "movieclapper"
        }
    }
}

extension EasySweepCatalog {

    /// `categories.json`, decoded once. Empty if the file is missing or
    /// unreadable, which leaves every section on its built-in glyph and raw id.
    private static let categoryPresentations: [String: Presentation] = {
        guard let url = Bundle.module.url(
            forResource: "categories",
            withExtension: "json",
            subdirectory: "Catalog"
        ), let data = try? Data(contentsOf: url),
        let raw = try? JSONDecoder().decode([String: Presentation].self, from: data)
        else { return [:] }
        return raw
    }()

    static let categorySymbols: [String: String] =
        categoryPresentations.compactMapValues(\.symbol)

    /// The data-driven presentation for a section. A struct keeps symbols and
    /// locale-keyed copy extensible without changing the category map's shape.
    private struct Presentation: Decodable {
        let symbol: String?
        let localizations: [String: Localization]?

        func name(for locale: Locale) -> String? {
            guard let localizations else { return nil }

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
                if let match = localizations.first(where: {
                    $0.key.compare(candidate, options: .caseInsensitive) == .orderedSame
                }), let name = match.value.name, !name.isEmpty {
                    return name
                }
            }
            return nil
        }

        struct Localization: Decodable {
            let name: String?
        }
    }
}
