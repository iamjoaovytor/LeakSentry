import Combine
import LeakSentry

/// Adopt this protocol on any ObservableObject ViewModel to enable leak monitoring.
///
/// Usage:
/// ```swift
/// class MyViewModel: ObservableObject, LeakSentinel { ... }
///
/// // In the View:
/// MyView().trackLeaks(for: viewModel)
/// ```
public protocol LeakSentinel: AnyObject, ObservableObject {}
