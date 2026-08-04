import Foundation

/// The published list of cleanable developer locations.
///
/// Data only. What may be deleted without asking, and what needs a tool rather
/// than the filesystem, are decisions for the app consuming this — see
/// `Entry`.
public enum EasySweepCatalog {

    /// Every entry, in category order.
    public static let all: [Entry] = Category.allCases.flatMap(entries(in:))

    /// The entries for one section.
    ///
    /// Decoded **per entry**, skipping any that fail. One malformed record in a
    /// newer catalog must not blank an entire section in an older build; a
    /// missing row is a bug, an empty section looks like "nothing to clean".
    public static func entries(in category: Category) -> [Entry] {
        guard let url = Bundle.module.url(
            forResource: category.rawValue,
            withExtension: "json",
            subdirectory: "Catalog"
        ), let data = try? Data(contentsOf: url) else {
            return []
        }

        let decoder = JSONDecoder()
        guard let raw = try? decoder.decode([SkippingFailures].self, from: data) else {
            return []
        }
        return raw.compactMap(\.entry)
    }

    /// A decoded entry, or nothing if that one record was unreadable.
    private struct SkippingFailures: Decodable {
        let entry: Entry?

        init(from decoder: any Decoder) throws {
            entry = try? Entry(from: decoder)
        }
    }
}
