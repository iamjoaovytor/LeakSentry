import LeakSentry

/// Adopt this protocol on any ViewModel to enable leak monitoring.
/// Works with both `ObservableObject` and `@Observable` classes.
///
/// Usage:
/// ```swift
/// class MyViewModel: ObservableObject, LeakSentinel { ... }
///
/// @Observable
/// class MyViewModel: LeakSentinel { ... }
///
/// // In the View:
/// MyView().trackLeaks(for: viewModel)
/// ```
public protocol LeakSentinel: AnyObject {}
