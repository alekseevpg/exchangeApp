import Foundation
import UIKit
import SnapKit
import RxSwift
import RxCocoa

class ExchangeViewController: UIViewController {
    var disposeBag = DisposeBag()
    lazy var toAmountField: UITextField = {
        return self.createAmountField()
    }()
    lazy var fromAmountField: UITextField = {
        return self.createAmountField()
    }()
    var viewModel = ExchangeViewModel()
    var scroll1: CurrencyScrollView!
    var scroll2: CurrencyScrollView!

    override func viewDidLoad() {
        super.viewDidLoad()

        scroll1 = CurrencyScrollView(viewModel: viewModel.fromScrollViewModel)
        view.addSubview(scroll1)
        scroll1.snp.makeConstraints({ make in
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalTo(view.snp.centerY)
        })

        view.addSubview(fromAmountField)
        fromAmountField.snp.makeConstraints({ make in
            make.leading.equalTo(scroll1.snp.centerX)
            make.trailing.equalToSuperview().offset(-45)
            make.centerY.equalTo(scroll1.snp.centerY)
        })
        fromAmountField.adjustsFontSizeToFitWidth = true

        fromAmountField.rx.text
                .subscribe(onNext: { next in
                    self.viewModel.fromAmountString.value = next ?? ""
                })
                .addDisposableTo(disposeBag)

        viewModel.fromAmount.asObservable()
                .map({ item in
                    item.toString()
                })
                .bind(to: fromAmountField.rx.text)
                .addDisposableTo(disposeBag)

        scroll2 = CurrencyScrollView(viewModel: viewModel.toScrollViewModel)
        view.addSubview(scroll2)
        scroll2.snp.makeConstraints({ make in
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.top.equalTo(scroll1.snp.bottom)
            make.bottom.equalToSuperview()
        })

        view.addSubview(toAmountField)
        toAmountField.snp.makeConstraints({ make in
            make.leading.equalTo(scroll2.snp.centerX)
            make.trailing.equalToSuperview().offset(-45)
            make.centerY.equalTo(scroll2.snp.centerY)
        })

        toAmountField.rx.text
                .subscribe(onNext: { next in
                    self.viewModel.toFieldUpdate(next)
                })
                .addDisposableTo(disposeBag)

        viewModel.toAmount.asObservable()
                .map({ item in
                    item.toString()
                })
                .bind(to: toAmountField.rx.text)
                .addDisposableTo(disposeBag)

        let exchangeBtn = UIButton()
        exchangeBtn.setTitle("Exchange", for: .normal)
        exchangeBtn.setTitleColor(.white, for: .normal)
        exchangeBtn.setTitleColor(UIColor.white.withAlphaComponent(0.3), for: .highlighted)
        exchangeBtn.setTitleColor(UIColor.white.withAlphaComponent(0.3), for: .disabled)
        exchangeBtn.rx.tap.subscribe(onNext: { [unowned self] in
            self.viewModel.exchange()
        }).addDisposableTo(disposeBag)
        view.addSubview(exchangeBtn)
        exchangeBtn.snp.makeConstraints({ make in
            make.trailing.equalToSuperview()
            make.top.equalToSuperview().offset(20)
            make.width.equalTo(100)
        })
        viewModel.sufficientFundsToExchange.asObservable()
                .subscribe(onNext: { value in
                    exchangeBtn.isEnabled = value
                })
                .addDisposableTo(disposeBag)

        Observable.combineLatest(viewModel.sufficientFundsToExchange.asObservable(),
                viewModel.toAmount.asObservable(),
                viewModel.fromAmount.asObservable(),
                viewModel.fromScrollViewModel.currentItem.asObservable(),
                viewModel.toScrollViewModel.currentItem.asObservable()
        ).subscribe(onNext: { _ in
            exchangeBtn.isEnabled = self.viewModel.sufficientFundsToExchange.value &&
                    self.viewModel.toAmount.value != nil &&
                    self.viewModel.fromAmount.value != nil &&
                    self.viewModel.fromScrollViewModel.currentItem.value !=
                            self.viewModel.toScrollViewModel.currentItem.value
        }).addDisposableTo(disposeBag)

        var exchangeRateLbl = UILabel()
        exchangeRateLbl.textAlignment = .center
        exchangeRateLbl.textColor = .white
        view.addSubview(exchangeRateLbl)
        exchangeRateLbl.snp.makeConstraints({ make in
            make.centerX.equalToSuperview()
            make.trailing.equalTo(exchangeBtn.snp.leading)
            make.bottom.equalTo(exchangeBtn.snp.bottom)
            make.top.equalTo(exchangeBtn.snp.top)
        })

        viewModel.currentExchangeRate.asObservable()
                .bind(to: exchangeRateLbl.rx.text)
                .addDisposableTo(disposeBag)

        keyboardHeight()
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { (newKeyboardHeight: CGFloat) in
                    self.scroll1.snp.updateConstraints({ make in
                        make.bottom.equalTo(self.view.snp.centerY).offset(-newKeyboardHeight / 2)
                    })
                    self.scroll2.snp.updateConstraints({ make in
                        make.bottom.equalToSuperview().offset(-newKeyboardHeight)
                    })
                    self.scroll1.updateFrame()
                    self.scroll2.updateFrame()
                })
                .addDisposableTo(disposeBag)

        let radialLayer = RadialGradientLayer()
        self.view.layer.insertSublayer(radialLayer, at: 0)
        radialLayer.frame = view.bounds
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        scroll1.updateFrame()
        scroll2.updateFrame()

        let shadedLayer = ShadedLayer()
        scroll2.layer.addSublayer(shadedLayer)
        shadedLayer.frame = scroll2.bounds
    }

    private func createAmountField() -> UITextField {
        var field = UITextField()
        field.font = UIFont.systemFont(ofSize: 25)
        field.textColor = .white
        field.textAlignment = .right
        field.keyboardType = .numberPad
        field.adjustsFontSizeToFitWidth = true
        return field
    }

}
