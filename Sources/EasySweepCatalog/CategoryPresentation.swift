import AppKit

extension EasySweepCatalog.Category {

    /// The section title for a locale, falling back through a regional/script
    /// match, the language, and finally English. The config uses BCP-47 keys,
    /// so adding another locale is data-only.
    public func localizedName(for locale: Locale = .current) -> String {
        guard let presentation = EasySweepCatalog.categoryPresentations[rawValue],
              let localizations = presentation.localizations,
              let name = CatalogLocalization.resolve(localizations, locale: locale, value: \.name)
        else { return rawValue }
        return name
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
        let localizations: [String: EasySweepCatalog.LocalizedContent]?
    }
}
