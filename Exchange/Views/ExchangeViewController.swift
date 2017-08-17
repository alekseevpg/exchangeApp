import Foundation
import UIKit
import SnapKit
import RxSwift
import RxCocoa

class ExchangeViewController: UIViewController {
    private var disposeBag = DisposeBag()

    private lazy var exchangeBtn = UIButton()
    private lazy var exchangeRateLbl = UILabel()
    private lazy var exchangeRateRevertedLbl = UILabel()
    private lazy var fromAmountField = AmountTextField(prefix: "-")
    private lazy var toAmountField = AmountTextField(prefix: "+")

    private var viewModel = ExchangeViewModel()
    private var fromScrollView: CurrencyScrollView!
    private var toScrollView: CurrencyScrollView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.createViews()
        self.setupConstraints()
        self.bindModel()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.fromScrollView.updateFrame()
        self.toScrollView.updateFrame()
        self.createAdditionalLayers()
    }

    private func createViews() {
        fromScrollView = CurrencyScrollView(viewModel: viewModel.fromScrollViewModel)
        view.addSubview(fromScrollView)

        view.addSubview(fromAmountField)
        fromAmountField.becomeFirstResponder()

        toScrollView = CurrencyScrollView(viewModel: viewModel.toScrollViewModel, shaded: true)
        view.addSubview(toScrollView)
        view.addSubview(toAmountField)
        toAmountField.textColor = UIColor.white.withAlphaComponent(0.8)
        toAmountField.prefixLbl.textColor = UIColor.white.withAlphaComponent(0.8)

        exchangeBtn.setTitle("Exchange", for: .normal)
        exchangeBtn.setTitleColor(.white, for: .normal)
        exchangeBtn.setTitleColor(UIColor.white.withAlphaComponent(0.3), for: .highlighted)
        exchangeBtn.setTitleColor(UIColor.white.withAlphaComponent(0.3), for: .disabled)
        view.addSubview(exchangeBtn)

        exchangeRateLbl.textAlignment = .right
        exchangeRateLbl.font = UIFont.systemFont(ofSize: 13, weight: UIFontWeightSemibold)
        exchangeRateLbl.textColor = .white
        view.addSubview(exchangeRateLbl)

        exchangeRateRevertedLbl.textAlignment = .right
        exchangeRateRevertedLbl.font = UIFont.systemFont(ofSize: 13, weight: UIFontWeightSemibold)
        exchangeRateRevertedLbl.textColor = UIColor.white.withAlphaComponent(0.8)
        view.addSubview(exchangeRateRevertedLbl)
    }

    private func setupConstraints() {
        exchangeBtn.snp.makeConstraints({ make in
            make.trailing.equalToSuperview()
            make.top.equalToSuperview().offset(20)
            make.width.equalTo(100)
        })

        fromScrollView.snp.makeConstraints({ make in
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalTo(view.snp.centerY)
        })

        fromAmountField.snp.makeConstraints({ make in
            make.width.equalTo(20)
            make.trailing.equalToSuperview().offset(-45)
            make.centerY.equalTo(fromScrollView.snp.centerY)
        })
        exchangeRateLbl.snp.makeConstraints({ make in
            make.leading.equalTo(view.snp.centerX)
            make.trailing.equalTo(fromAmountField.snp.trailing)
            make.top.equalTo(fromAmountField.snp.bottom).offset(20)
        })

        toScrollView.snp.makeConstraints({ make in
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.top.equalTo(fromScrollView.snp.bottom)
            make.bottom.equalToSuperview()
        })
        toAmountField.snp.makeConstraints({ make in
            make.width.equalTo(20)
            make.trailing.equalToSuperview().offset(-45)
            make.centerY.equalTo(toScrollView.snp.centerY)
        })

        exchangeRateRevertedLbl.snp.makeConstraints({ make in
            make.leading.equalTo(view.snp.centerX)
            make.trailing.equalTo(toAmountField.snp.trailing)
            make.top.equalTo(toAmountField.snp.bottom).offset(20)
        })
    }

    private func createAdditionalLayers() {
        let radialLayer = RadialGradientLayer()
        self.view.layer.insertSublayer(radialLayer, at: 0)
        radialLayer.frame = view.bounds
    }

    private func bindModel() {
        fromAmountField.rx.text
                .subscribe(onNext: { (next: String?) in
                    //If last character is one of (.,) we assume that user didn't end his input and we shoudln't update
                    var value = next ?? ""
                    if let last = value.characters.last, (last == "." || last == ",") {
                    } else {
                        self.viewModel.fromAmountInput.value = value
                    }
                    self.fromAmountField.setWidthToFitText()
                })
                .addDisposableTo(disposeBag)

        viewModel.fromAmountOutput.asDriver()
                .map({ item in
                    item.toString()
                })
                .drive(onNext: { next in
                    self.fromAmountField.text = next
                    self.fromAmountField.setWidthToFitText()
                })
                .addDisposableTo(disposeBag)

        toAmountField.rx.text
                .subscribe(onNext: { (next: String?) in
                    //If last character is one of (.,) we assume that user didn't end his input and we shoudln't update
                    var value = next ?? ""
                    if let last = value.characters.last, (last == "." || last == ",") {
                    } else {
                        self.viewModel.toFieldUpdate(value)
                    }
                    self.toAmountField.setWidthToFitText()
                })
                .addDisposableTo(disposeBag)

        viewModel.toAmountOutput.asDriver()
                .map({ item in
                    item.toString()
                })
                .drive(onNext: { next in
                    self.toAmountField.text = next
                    self.toAmountField.setWidthToFitText()
                })
                .addDisposableTo(disposeBag)

        exchangeBtn.rx.tap.subscribe(onNext: { _ in
            self.viewModel.exchange()
            self.fromAmountField.becomeFirstResponder()
        }).addDisposableTo(disposeBag)

        viewModel.exchangeBtnEnabled
                .bind(to: exchangeBtn.rx.isEnabled)
                .addDisposableTo(disposeBag)

        viewModel.amountPrefixIsHidden
                .bind(to: fromAmountField.prefixLbl.rx.isHidden)
                .addDisposableTo(disposeBag)

        viewModel.amountPrefixIsHidden
                .bind(to: toAmountField.prefixLbl.rx.isHidden)
                .addDisposableTo(disposeBag)

        viewModel.exchangeRate.asObservable()
                .bind(to: exchangeRateLbl.rx.text)
                .addDisposableTo(disposeBag)

        viewModel.exchangeRateReverted.asObservable()
                .bind(to: exchangeRateRevertedLbl.rx.text)
                .addDisposableTo(disposeBag)

        keyboardHeight()
                .asDriver(onErrorJustReturn: 0)
                .drive(onNext: { (newKeyboardHeight: CGFloat) in
                    self.fromScrollView.snp.updateConstraints({ make in
                        make.bottom.equalTo(self.view.snp.centerY).offset(-newKeyboardHeight / 2)
                    })
                    self.toScrollView.snp.updateConstraints({ make in
                        make.bottom.equalToSuperview().offset(-newKeyboardHeight)
                    })
                    self.fromScrollView.updateFrame()
                    self.toScrollView.updateFrame()
                })
                .addDisposableTo(disposeBag)
    }
}
