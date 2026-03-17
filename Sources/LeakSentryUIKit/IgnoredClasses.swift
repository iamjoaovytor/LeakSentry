#if canImport(UIKit)
let defaultIgnoredViewControllerClasses: Set<String> = [
    "UINavigationController",
    "UITabBarController",
    "UISplitViewController",
    "UIPageViewController",
    "UIInputWindowController",
    "UICompatibilityInputViewController",
    "UISystemKeyboardDockController",
    "UIRemoteKeyboardViewController",
    "UIEditingOverlayViewController",
    "UIKeyboardCandidateGridCollectionViewController",
    "UIKeyboardCandidateRowViewController",
    "UIActivityGroupViewController",
    "UIAlertController",
]

let defaultIgnoredViewClasses: Set<String> = [
    "UIWindow",
    "UITransitionView",
    "UIDropShadowView",
    "UITextEffectsWindow",
    "UILayoutContainerView",
    "UINavigationTransitionView",
    "UIViewControllerWrapperView",
]
#endif
