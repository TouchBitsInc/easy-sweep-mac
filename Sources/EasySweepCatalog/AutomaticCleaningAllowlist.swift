extension EasySweepCatalog {
    /// IDs whose bundled paths have received the second, code-level approval
    /// required for unattended removal.
    ///
    /// Kept in compiled code as a second key: changing contributable JSON alone
    /// cannot widen automatic deletion. A new automatic target must update both
    /// its visible catalog declaration and this deliberately boring list.
    static let reviewedAutomaticCleaningIDs: Set<String> = [
        "ableton-decoding-cache", "after-effects-disk-cache", "android",
        "android-studio-cache", "arc-cache", "brave-cache", "bun",
        "cabal-packages", "camera-raw-cache", "capcut-cache", "cargo",
        "carthage", "ccache", "chrome-cache", "chrome-canary-cache",
        "chromium-cache", "claude-cli-cache", "cocoapods", "codeium-browser",
        "codex-app-cache", "codex-app-updates", "composer", "composer-library",
        "coredevice-cache", "cursor-cache", "deno", "derived-data", "dia-cache",
        "documentation", "duckduckgo-cache", "edge-cache", "electron",
        "firefox-cache", "gemini-tmp", "go-build", "go-modules", "gradle",
        "homebrew", "jetbrains", "librewolf-cache", "lightroom-video-cache",
        "lima-images", "media-encoder-cache", "mise-cache", "node-gyp",
        "npm-cache", "nuget", "nvm", "opera-cache", "opera-gx-cache",
        "orion-cache", "photoshop-cache", "pip", "playwright", "playwright-go",
        "pnpm", "pnpm-store-home", "poetry-cache", "premiere-media-cache",
        "qihoo-browser-cache", "qq-browser-cache", "rustup-downloads",
        "safari-cache", "sbt-ivy-cache", "sccache", "sdkman",
        "simulator-caches", "squirrel-updater-staging", "stack-snapshots",
        "swiftpm-cache", "tart-images", "teams-cache", "terraform-plugins",
        "tor-browser-cache", "typescript", "uv-cache", "vivaldi-cache", "vscode",
        "wallpaper-aerials", "waterfox-cache", "xcode-app-cache", "xdg-cache",
        "yandex-cache", "yarn", "zen-cache",
    ]
}
