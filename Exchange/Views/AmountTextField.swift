import Foundation
import UIKit
import SnapKit
import RxSwift
import RxCocoa

class AmountTextField: UITextField {

    lazy var prefixLbl = UILabel()
    var prefix = ""
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
        self.keyboardType = .numberPad
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
        return result && (newLength < text.characters.count || newLength <= 7)
    }

}