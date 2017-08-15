import Foundation
import UIKit
import SnapKit
import RxSwift
import RxCocoa

class ExchangeViewController: UIViewController {
    var disposeBag = DisposeBag()
    lazy var exchangeBtn = UIButton()
    lazy var exchangeRateLbl = UILabel()
    lazy var exchangeRateRevertedLbl = UILabel()

    lazy var toAmountField: UITextField = {
        return self.createAmountField()
    }()
    lazy var fromAmountField: UITextField = {
        return self.createAmountField()
    }()
    var viewModel = ExchangeViewModel()
    var fromScrollView: CurrencyScrollView!
    var toScrollView: CurrencyScrollView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.createViews()
        self.setupConstraints()
        self.bindModel()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        fromScrollView.updateFrame()
        toScrollView.updateFrame()
        self.createAdditionalLayers()
    }

    private func createAdditionalLayers() {
        let radialLayer = RadialGradientLayer()
        self.view.layer.insertSublayer(radialLayer, at: 0)
        radialLayer.frame = view.bounds

        let shadedLayer = ShadedLayer()
        toScrollView.layer.addSublayer(shadedLayer)
        shadedLayer.frame = toScrollView.bounds
    }

    private func bindModel() {
        fromAmountField.rx.text
                .subscribe(onNext: { next in
                    self.viewModel.fromAmountInput.value = next ?? ""
                })
                .addDisposableTo(disposeBag)

        viewModel.fromAmountOutput.asObservable()
                .map({ item in
                    item.toString()
                })
                .bind(to: fromAmountField.rx.text)
                .addDisposableTo(disposeBag)

        toAmountField.rx.text
                .subscribe(onNext: { next in
                    self.viewModel.toFieldUpdate(next)
                })
                .addDisposableTo(disposeBag)

        viewModel.toAmountInput.asObservable()
                .map({ item in
                    item.toString()
                })
                .bind(to: toAmountField.rx.text)
                .addDisposableTo(disposeBag)

        exchangeBtn.rx.tap.subscribe(onNext: { [unowned self] in
            self.viewModel.exchange()
        }).addDisposableTo(disposeBag)

        Observable.combineLatest(viewModel.sufficientFundsToExchange.asObservable(),
                viewModel.toAmountInput.asObservable(),
                viewModel.fromAmountOutput.asObservable(),
                viewModel.fromScrollViewModel.currentItem.asObservable(),
                viewModel.toScrollViewModel.currentItem.asObservable()
        ).subscribe(onNext: { [unowned self] _ in
            self.exchangeBtn.isEnabled = self.viewModel.sufficientFundsToExchange.value &&
                    self.viewModel.toAmountInput.value != nil &&
                    self.viewModel.fromAmountOutput.value != nil &&
                    self.viewModel.fromScrollViewModel.currentItem.value !=
                            self.viewModel.toScrollViewModel.currentItem.value
        }).addDisposableTo(disposeBag)

        viewModel.exchangeRate.asObservable()
                .bind(to: exchangeRateLbl.rx.text)
                .addDisposableTo(disposeBag)

        viewModel.exchangeRateReverted.asObservable()
                .bind(to: exchangeRateRevertedLbl.rx.text)
                .addDisposableTo(disposeBag)
    }

    private func setupConstraints() {
        exchangeBtn.snp.makeConstraints({ make in
            make.trailing.equalToSuperview()
            make.top.equalToSuperview().offset(20)
            make.width.equalTo(100)
        })

        exchangeRateLbl.snp.makeConstraints({ make in
            make.centerX.equalToSuperview()
            make.trailing.equalTo(exchangeBtn.snp.leading)
            make.bottom.equalTo(exchangeBtn.snp.bottom)
            make.top.equalTo(exchangeBtn.snp.top)
        })

        fromScrollView.snp.makeConstraints({ make in
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalTo(view.snp.centerY)
        })

        fromAmountField.snp.makeConstraints({ make in
            make.leading.equalTo(fromScrollView.snp.centerX)
            make.trailing.equalToSuperview().offset(-45)
            make.centerY.equalTo(fromScrollView.snp.centerY)
        })

        toScrollView.snp.makeConstraints({ make in
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.top.equalTo(fromScrollView.snp.bottom)
            make.bottom.equalToSuperview()
        })
        toAmountField.snp.makeConstraints({ make in
            make.leading.equalTo(toScrollView.snp.centerX)
            make.trailing.equalToSuperview().offset(-45)
            make.centerY.equalTo(toScrollView.snp.centerY)
        })
        exchangeRateRevertedLbl.snp.makeConstraints({ make in
            make.leading.equalTo(toAmountField.snp.leading)
            make.trailing.equalTo(toAmountField.snp.trailing)
            make.top.equalTo(toAmountField.snp.bottom).offset(20)
        })

        keyboardHeight()
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { (newKeyboardHeight: CGFloat) in
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

    private func createViews() {
        fromScrollView = CurrencyScrollView(viewModel: viewModel.fromScrollViewModel)
        view.addSubview(fromScrollView)

        view.addSubview(fromAmountField)
        fromAmountField.adjustsFontSizeToFitWidth = true

        toScrollView = CurrencyScrollView(viewModel: viewModel.toScrollViewModel)
        view.addSubview(toScrollView)

        view.addSubview(toAmountField)

        exchangeBtn.setTitle("Exchange", for: .normal)
        exchangeBtn.setTitleColor(.white, for: .normal)
        exchangeBtn.setTitleColor(UIColor.white.withAlphaComponent(0.3), for: .highlighted)
        exchangeBtn.setTitleColor(UIColor.white.withAlphaComponent(0.3), for: .disabled)
        view.addSubview(exchangeBtn)

        exchangeRateLbl.textAlignment = .center
        exchangeRateLbl.textColor = .white
        view.addSubview(exchangeRateLbl)

        exchangeRateRevertedLbl.textAlignment = .right
        exchangeRateRevertedLbl.font = UIFont.systemFont(ofSize: 13, weight: UIFontWeightSemibold)
        exchangeRateRevertedLbl.textColor = UIColor.white.withAlphaComponent(0.8)
        view.addSubview(exchangeRateRevertedLbl)
    }

    private func createAmountField() -> UITextField {
        let field = UITextField()
        field.font = UIFont.systemFont(ofSize: 25)
        field.textColor = .white
        field.textAlignment = .right
        field.keyboardType = .numberPad
        field.adjustsFontSizeToFitWidth = true
        return field
    }
}
