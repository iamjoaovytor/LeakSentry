import SwiftUI
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
        self.modifier(LeakSentinelModifier(
            weakViewModel: WeakRef(viewModel),
            typeName: String(describing: type(of: viewModel)),
            callSite: "\(file):\(line)"
        ))
    }
}

private final class WeakRef<T: AnyObject>: @unchecked Sendable {
    weak var value: T?
    init(_ value: T) { self.value = value }
}

/// Checks if an @Observable object has stored closure/function properties
/// that could cause retain cycles (e.g., `var onComplete: (() -> Void)?`).
/// Skips `_$observationRegistrar` and other observation infrastructure fields.
private func hasRetainCycleRisk(_ object: AnyObject) -> Bool {
    let mirror = Mirror(reflecting: object)
    for child in mirror.children {
        if let label = child.label, label.hasPrefix("_$") { continue }
        let typeName = String(describing: type(of: child.value))
        if typeName.contains("->") { return true }
    }
    return false
}

private struct LeakSentinelModifier<VM: LeakSentinel>: ViewModifier {
    let weakViewModel: WeakRef<VM>
    let typeName: String
    let callSite: String
    @State private var disappearTask: Task<Void, Never>?

    func body(content: Content) -> some View {
        let site = callSite
        let name = typeName
        let weakVM = weakViewModel

        return content
            .onAppear {
                disappearTask?.cancel()
                disappearTask = nil
            }
            .onDisappear {
                disappearTask = Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    guard !Task.isCancelled else { return }

                    if let vm = weakVM.value {
                        // For @Observable classes (not ObservableObject), SwiftUI's @State
                        // retains the object indefinitely (~14 refs). Only track if stored
                        // closures suggest a potential retain cycle.
                        if !(vm is any ObservableObject), !hasRetainCycleRisk(vm) {
                            disappearTask = nil
                            return
                        }

                        let context = ["Location": site]
                        LeakDetector.shared.track(vm, description: name, context: context)
                    }
                    disappearTask = nil
                }
            }
    }
}
