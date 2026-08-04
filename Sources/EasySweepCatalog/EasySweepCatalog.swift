import Foundation

/// The published list of cleanable developer locations.
///
/// Data only. What may be deleted without asking, and what needs a tool rather
/// than the filesystem, are decisions for the app consuming this — see
/// `CatalogEntry`.
public enum EasySweepCatalog {

    /// Every entry, in category order.
    public static let all: [CatalogEntry] = CatalogCategory.allCases.flatMap(entries(in:))

    /// The entries for one section.
    ///
    /// Decoded **per entry**, skipping any that fail. One malformed record in a
    /// newer catalog must not blank an entire section in an older build; a
    /// missing row is a bug, an empty section looks like "nothing to clean".
    public static func entries(in category: CatalogCategory) -> [CatalogEntry] {
        guard let url = resourceBundle.url(
            forResource: category.rawValue,
            withExtension: "json",
            subdirectory: "Catalog"
        ) ?? resourceBundle.url(
            forResource: category.rawValue,
            withExtension: "json"
        ), let data = try? Data(contentsOf: url) else {
            return []
        }

        let decoder = JSONDecoder()
        guard let raw = try? decoder.decode([SkippingFailures].self, from: data) else {
            return []
        }
        return raw.compactMap(\.entry)
    }

    /// Where the JSON lives.
    ///
    /// These sources are built two ways. Built by SwiftPM they are a package
    /// and the JSON is a bundled resource. Vendored into an app — copied in
    /// wholesale, so the app takes a reviewed snapshot rather than resolving a
    /// dependency at build time — there is no module bundle and the files sit
    /// in the app's own. `SWIFT_PACKAGE` is defined only in the first case.
    static var resourceBundle: Bundle {
        #if SWIFT_PACKAGE
        return .module
        #else
        return .main
        #endif
    }

    /// A decoded entry, or nothing if that one record was unreadable.
    private struct SkippingFailures: Decodable {
        let entry: CatalogEntry?

        init(from decoder: any Decoder) throws {
            entry = try? CatalogEntry(from: decoder)
        }
    }
}
