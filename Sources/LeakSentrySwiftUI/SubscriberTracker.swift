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
    public func trackLeaks<VM: LeakSentinel>(
        for viewModel: VM,
        file: String = #fileID,
        line: Int = #line
    ) -> some View {
        self.modifier(LeakSentinelModifier(viewModel: viewModel, callSite: "\(file):\(line)"))
    }
}

private struct LeakSentinelModifier<VM: LeakSentinel>: ViewModifier {
    let viewModel: VM
    let callSite: String
    @State private var disappearTask: Task<Void, Never>?

    func body(content: Content) -> some View {
        content
            .onAppear {
                disappearTask?.cancel()
                disappearTask = nil
            }
            .onDisappear {
                let vm = viewModel
                let site = callSite
                disappearTask = Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    guard !Task.isCancelled else { return }

                    let typeName = String(describing: type(of: vm))
                    let context = [
                        "Location": site,
                    ]
                    LeakDetector.shared.track(vm, description: typeName, context: context)
                }
            }
    }
}
