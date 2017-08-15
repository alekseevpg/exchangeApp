import Foundation
import UIKit
import SnapKit

class CurrencyView: UIView {
    lazy var titleLbl = UILabel()
    lazy var amountLbl = UILabel()

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    public init() {
        super.init(frame: .zero)
        titleLbl.textColor = .white
        titleLbl.textAlignment = .left
        titleLbl.font = UIFont.systemFont(ofSize: 25)
        addSubview(titleLbl)

        titleLbl.snp.makeConstraints({ make in
            make.leading.equalToSuperview().offset(45)
            make.trailing.equalTo(snp.centerX)
            make.centerY.equalToSuperview()
        })

        amountLbl.textColor = UIColor.white
        amountLbl.textAlignment = .left
        amountLbl.font = UIFont.systemFont(ofSize: 13, weight: UIFontWeightSemibold)
        addSubview(amountLbl)

        amountLbl.snp.makeConstraints({ make in
            make.leading.equalTo(titleLbl.snp.leading)
            make.trailing.equalTo(snp.centerX)
            make.top.equalTo(titleLbl.snp.bottom).offset(20)
        })
    }
}
