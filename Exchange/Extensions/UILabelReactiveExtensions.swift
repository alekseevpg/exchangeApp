import RxSwift
import UIKit
import RxCocoa

extension Reactive where Base: UILabel {

    /// Bindable sink for `text` property.
    public var textColor: UIBindingObserver<Base, UIColor?> {
        return UIBindingObserver(UIElement: self.base) { label, color in
            label.textColor = color
        }
    }
}
