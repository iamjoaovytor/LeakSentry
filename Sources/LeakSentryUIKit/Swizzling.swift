#if canImport(UIKit)
import ObjectiveC.runtime

func swizzleInstanceMethod(_ cls: AnyClass, original: Selector, swizzled: Selector) {
    guard
        let originalMethod = class_getInstanceMethod(cls, original),
        let swizzledMethod = class_getInstanceMethod(cls, swizzled)
    else { return }
    method_exchangeImplementations(originalMethod, swizzledMethod)
}
#endif
