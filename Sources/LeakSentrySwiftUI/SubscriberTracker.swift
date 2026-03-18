import SwiftUI
import Combine
import LeakSentry

extension View {
    /// Monitors the given ViewModel for memory leaks.
    ///
    /// Detection triggers when the view disappears and does not reappear
    /// within a short grace period — avoiding false positives from
    /// NavigationStack pushes where `onDisappear` fires but the view
    /// is still in the stack.
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
    @State private var disappearTask: Task<Void, Never>?

    func body(content: Content) -> some View {
        content
            .onAppear {
                // View reappeared (e.g. popped back) — cancel pending check
                disappearTask?.cancel()
                disappearTask = nil
            }
            .onDisappear {
                let vm = viewModel
                // Wait a grace period to see if onAppear fires again.
                // If not, the view was truly removed from the hierarchy.
                disappearTask = Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s grace
                    guard !Task.isCancelled else { return }

                    let typeName = String(describing: type(of: vm))
                    let context = [
                        "Source": "SwiftUI .trackLeaks(for:)",
                        "ViewModel": typeName,
                    ]
                    LeakDetector.shared.track(vm, description: typeName, context: context)
                }
            }
    }
}
