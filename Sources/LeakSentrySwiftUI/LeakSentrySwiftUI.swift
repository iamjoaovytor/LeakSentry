import LeakSentry

extension LeakSentry {
    /// Call this at app launch when using SwiftUI ViewModels.
    /// Use `.trackLeaks(for: viewModel)` on Views to enable per-ViewModel monitoring.
    @MainActor
    public static func startSwiftUI(configuration: Configuration = .default) {
        start(configuration: configuration)
    }
}
