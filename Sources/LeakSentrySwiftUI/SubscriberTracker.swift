import SwiftUI
import Combine
import LeakSentry

extension View {
    /// Monitors the given ViewModel for memory leaks.
    /// Leak detection triggers when this View disappears.
    ///
    /// Usage:
    /// ```swift
    /// MyView()
    ///     .trackLeaks(for: viewModel)
    /// ```
    public func trackLeaks<VM: LeakSentinel>(for viewModel: VM) -> some View {
        self.modifier(LeakSentinelModifier(viewModel: viewModel))
    }
}

private struct LeakSentinelModifier<VM: LeakSentinel>: ViewModifier {
    let viewModel: VM

    func body(content: Content) -> some View {
        content.onDisappear {
            let typeName = String(describing: type(of: viewModel))
            Task { @MainActor in
                LeakDetector.shared.track(viewModel, description: typeName)
            }
        }
    }
}
