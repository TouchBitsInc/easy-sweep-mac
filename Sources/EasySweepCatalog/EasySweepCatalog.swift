import Foundation

/// The published list of cleanable macOS locations.
///
/// Data only. The catalog publishes a conservative unattended-clean permission;
/// a consumer still owns path validation, process checks, and deletion.
public enum EasySweepCatalog {

    /// Every entry, in category order.
    public static let all: [Entry] = Category.allCases.flatMap(entries(in:))

    /// The entries for one section.
    ///
    /// Decoded **per entry**, skipping any that fail. One malformed record in a
    /// newer catalog must not blank an entire section in an older build; a
    /// missing row is a bug, an empty section looks like "nothing to clean".
    public static func entries(in category: Category) -> [Entry] {
        guard let data = catalogData(in: category) else {
            return []
        }

        let decoder = JSONDecoder()
        guard let raw = try? decoder.decode([SkippingFailures].self, from: data) else {
            return []
        }
        return raw.compactMap(\.entry)
    }

    /// Raw bundled data for validation. Internal so tests can require fields
    /// that deliberately have conservative decode defaults for older clients.
    static func catalogData(in category: Category) -> Data? {
        guard let url = Bundle.module.url(
            forResource: category.rawValue,
            withExtension: "json",
            subdirectory: "Catalog"
        ), let data = try? Data(contentsOf: url) else {
            return nil
        }
        return data
    }

    /// A decoded entry, or nothing if that one record was unreadable.
    private struct SkippingFailures: Decodable {
        let entry: Entry?

        init(from decoder: any Decoder) throws {
            entry = try? Entry(from: decoder)
        }
    }
}
