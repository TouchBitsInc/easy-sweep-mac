import Foundation
import Testing

@testable import EasySweepCatalog

/// 2.0.0 reshaped every entry. What it must not have done is rename one.
///
/// Ids travel far outside this package: the consuming app keys its safety table
/// by them, a synced automation rule names a catalogued target by id, and the
/// statistics history records what was cleaned by id. A rename is silent
/// everywhere — the rule stops matching, the history stops adding up — and it
/// reaches Macs still running the older build.
@Suite("1.x ids survive")
struct MigrationTests {

    /// Every id published by 1.3.2, the last release before the reshape.
    static let published: Set<String> = [
        "ableton-decoding-cache", "after-effects-disk-cache", "anaconda-packages",
        "android", "android-studio-cache", "arc-cache", "arc-site-cache", "archives",
        "brave-cache", "brave-site-cache", "bun", "camera-raw-cache", "capcut-cache",
        "cargo", "carthage", "ccache", "chrome-cache", "chrome-site-cache", "claude-caches",
        "claude-cli-cache", "claude-projects", "cocoapods", "cocoapods-repos",
        "codeium-browser", "codex-app-cache", "codex-app-updates", "codex-sessions",
        "composer", "composer-library", "conda-packages", "configurator-temp",
        "coredevice-cache", "crash-reports", "cursor-cache", "deno", "derived-data",
        "device-software-updates", "documentation", "dropbox-cache", "dvt-downloads",
        "edge-cache", "edge-site-cache", "electron", "electron-code-caches",
        "electron-http-caches", "expo-cache", "firefox-cache", "gemini-tmp", "go-build",
        "go-modules", "google-drive-cache", "gradle", "homebrew", "ios-device-support",
        "jetbrains", "lightroom-video-cache", "lima-images", "lmstudio-backends",
        "lmstudio-models", "mambaforge-packages", "maven", "media-encoder-cache",
        "miniconda-packages", "miniforge-packages", "mise-cache", "music-artwork-cache",
        "node-gyp", "npm-cache", "nuget", "nvm", "ollama-models", "onedrive-cache",
        "photoshop-cache", "pip", "playground-devices", "playwright", "playwright-go",
        "pnpm", "poetry-cache", "premiere-media-cache", "pub-cache", "rustup-toolchains",
        "safari-cache", "saved-app-state", "sbt-ivy-cache", "sccache", "sdkman",
        "simulator-caches", "simulator-devices", "spotify-cache",
        "squirrel-updater-staging", "swiftpm-cache", "tart-images", "tvos-device-support",
        "typescript", "user-logs", "uv-cache", "vagrant-boxes", "vscode",
        "wallpaper-aerials", "watchos-device-support", "xcode-app-cache",
        "xcode-products-logs", "xcode-system-resources", "xcodebuildmcp", "xctest-devices",
        "xdg-cache", "yarn",
    ]

    /// Entries taken out on purpose, and why. An id may leave the catalogue —
    /// but only as a decision somebody wrote down, never as a side effect of an
    /// edit.
    static let withdrawn: [String: String] = [
        // Named the installed toolchains rather than rustup's download cache,
        // and called them safe. Cleaning it took every Rust compiler on the
        // machine, the one in use included. Replaced by `rustup-downloads`,
        // which is what the nvm and sdkman entries beside it already do.
        "rustup-toolchains": "replaced by rustup-downloads"
    ]

    @Test func nothingPublishedWasRenamedOrDropped() {
        let current = Set(EasySweepCatalog.all.map(\.id))
        let missing = Self.published
            .subtracting(current)
            .subtracting(Self.withdrawn.keys)
            .sorted()
        #expect(missing.isEmpty, "renamed or dropped since 1.3.2: \(missing)")
    }

    /// A withdrawal that has quietly come back should stop being listed as one.
    @Test func withdrawalsAreStillWithdrawn() {
        let current = Set(EasySweepCatalog.all.map(\.id))
        for id in Self.withdrawn.keys {
            #expect(!current.contains(id), "\(id) is listed as withdrawn but is in the catalogue")
        }
    }

    /// `brandColor` became `color` in 2.4.0. The old spelling is not read: a
    /// catalog file still carrying it decodes with no colour rather than
    /// failing, which is what `color` being optional already buys.
    @Test func colourIsWrittenUnderItsCurrentName() throws {
        let entry = EasySweepCatalog.Entry(
            id: "example", name: "Example", detail: "Refetched on next build.",
            path: "~/Library/Caches/example", color: "#CB3837"
        )
        let written = String(decoding: try JSONEncoder().encode(entry), as: UTF8.self)
        #expect(written.contains("\"color\""))

        let decoded = try JSONDecoder().decode(
            EasySweepCatalog.Entry.self, from: Data(written.utf8))
        #expect(decoded.color == "#CB3837")
    }

    /// Adding is fine — this only pins that the reshape was a reshape.
    @Test func theCatalogueOnlyGrew() {
        #expect(EasySweepCatalog.all.count >= Self.published.count)
    }
}
