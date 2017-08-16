import Foundation
import UIKit

class AmountTextField: UITextField {

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    init() {
        super.init(frame: .zero)
        self.backgroundColor = .red
        self.placeholder = "0"
        self.font = UIFont.systemFont(ofSize: 25)
        self.textColor = .white
        self.textAlignment = .right
        self.keyboardType = .numberPad
        self.adjustsFontSizeToFitWidth = true
        self.delegate = self
    }

}
