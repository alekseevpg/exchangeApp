import RxSwift
import UIKit
import RxCocoa

extension Reactive where Base: UILabel {
    public var textColor: UIBindingObserver<Base, UIColor?> {
        return UIBindingObserver(UIElement: self.base) { label, color in
            label.textColor = color
        }
    }
}
