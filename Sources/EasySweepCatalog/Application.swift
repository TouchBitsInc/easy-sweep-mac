import Foundation

extension EasySweepCatalog {
    /// An application heading in appData.json. Its children retain their
    /// own paths, risk levels and persisted identities.
    public struct Application: Codable, Identifiable, Hashable, Sendable {
        public let id: String
        public let name: String
        public let localizations: [String: LocalizedContent]
        public let entries: [Entry]

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(String.self, forKey: .id)
            name = try container.decode(String.self, forKey: .name)
            localizations = try container.decodeIfPresent(
                [String: LocalizedContent].self, forKey: .localizations
            ) ?? [:]
            entries = try container.decode([SkippingFailures].self, forKey: .entries)
                .compactMap(\.entry)
        }

        public func localizedName(for locale: Locale = .current) -> String {
            CatalogLocalization.resolve(localizations, locale: locale) { $0.name } ?? name
        }

    }

    public static let applications: [Application] = {
        guard let data = catalogData(in: .appData),
              let raw = try? JSONDecoder().decode([ApplicationRecord].self, from: data)
        else { return [] }
        return raw.compactMap(\.application)
    }()

    public static func application(containing entryID: String) -> Application? {
        applicationsByEntryID[entryID]
    }

    private static let applicationsByEntryID: [String: Application] = Dictionary(
        applications.flatMap { application in
            application.entries.map { ($0.id, application) }
        },
        uniquingKeysWith: { first, _ in first }
    )

    private struct ApplicationRecord: Decodable {
        let application: Application?

        init(from decoder: any Decoder) throws {
            application = try? Application(from: decoder)
        }
    }
}
