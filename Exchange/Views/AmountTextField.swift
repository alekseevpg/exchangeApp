import Foundation
import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class AmountTextField: UITextField {
    lazy var prefixLbl = UILabel()
    private var prefix = ""

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    init(prefix: String) {
        super.init(frame: .zero)
        self.prefix = prefix
        self.setupViews()
        self.setupConstraints()
    }

    private func setupViews() {
        self.placeholder = "0"
        self.font = UIFont.systemFont(ofSize: 25)
        self.textColor = .white
        self.textAlignment = .right
        self.keyboardType = .decimalPad
        self.delegate = self
        self.adjustsFontSizeToFitWidth = false
        self.adjustsFontForContentSizeCategory = true

        prefixLbl.textColor = .white
        prefixLbl.text = prefix
        self.addSubview(prefixLbl)
    }

    private func setupConstraints() {
        prefixLbl.snp.makeConstraints({ make in
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.trailing.equalTo(snp.leading).offset(5)
        })
    }

    func changePrefixVisibility(hidden: Bool) {
        self.prefixLbl.isHidden = hidden
    }

    func setWidthToFitText() {
        let amount = text == nil || text! == "" ? "0" : text!
        let width = amount.size(attributes: [NSFontAttributeName: font ?? UIFont.systemFont(ofSize: 25)]).width
        snp.updateConstraints({ make in
            make.width.equalTo(width + 10)
        })
    }
}

extension AmountTextField: UITextFieldDelegate {
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
                          replacementString string: String) -> Bool {
        guard let text = textField.text else {
            return true
        }
        var result = true
        if string.characters.count > 0 {
            let disallowedCharacterSet = NSCharacterSet(charactersIn: "0123456789.-").inverted
            let replacementStringIsLegal = string.rangeOfCharacter(from: disallowedCharacterSet) == nil
            result = replacementStringIsLegal
        }
        let newLength = text.characters.count + string.characters.count - range.length
        var components = text.components(separatedBy: CharacterSet(charactersIn: ",."))
        let precisionNotReached = components.count <= 1 || components[1].characters.count < 2
        return result && (newLength < text.characters.count || (newLength <= 7 && precisionNotReached))
    }
}
