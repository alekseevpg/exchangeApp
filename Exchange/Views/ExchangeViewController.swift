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

    private var fromScrollView = CurrencyScrollView()
    private var toScrollView = CurrencyScrollView(shaded: true)

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
        view.addSubview(fromScrollView)
        view.addSubview(fromAmountField)
        fromAmountField.becomeFirstResponder()
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
        let viewModel = ExchangeViewModel(exchangeTap: exchangeBtn.rx.tap.asObservable(),
                fromItem: fromScrollView.viewModel.currentItem,
                toItem: toScrollView.viewModel.currentItem,
                fromFieldText: fromAmountField.rx.text.orEmpty.asObservable(),
                toFieldText: toAmountField.rx.text.orEmpty.asObservable(),
                exchangeService: DIContainer.Instance.resolve(ExchangeRateServiceProtocol.self)!,
                accountsStorage: DIContainer.Instance.resolve(AccountStorage.self)!)

        toAmountField.rx.text
                .subscribe(onNext: { [unowned self] next in
                    self.toAmountField.setWidthToFitText()
                })
                .addDisposableTo(disposeBag)

        viewModel.toUpdated
                .map {
                    $0.toString()
                }
                .subscribe(onNext: { next in
                    self.toAmountField.text = next
                    self.toAmountField.setWidthToFitText()
                })
                .addDisposableTo(disposeBag)

        fromAmountField.rx.text
                .subscribe(onNext: { [unowned self] next in
                    self.fromAmountField.setWidthToFitText()
                })
                .addDisposableTo(disposeBag)

        viewModel.fromUpdated
                .map {
                    $0.toString()
                }
                .subscribe(onNext: { next in
                    self.fromAmountField.text = next
                    self.fromAmountField.setWidthToFitText()
                })
                .addDisposableTo(disposeBag)

        viewModel.exchanged.subscribe(onNext: { [unowned self] next in
            self.fromAmountField.becomeFirstResponder()
        }).addDisposableTo(disposeBag)

        viewModel.exchangeBtnEnabled
                .bind(to: exchangeBtn.rx.isEnabled)
                .addDisposableTo(disposeBag)

        viewModel.fromPrefixIsHidden
                .bind(to: fromAmountField.prefixLbl.rx.isHidden)
                .addDisposableTo(disposeBag)

        viewModel.toPrefixIsHidden
                .bind(to: toAmountField.prefixLbl.rx.isHidden)
                .addDisposableTo(disposeBag)

        viewModel.exchangeRate
                .bind(to: exchangeRateLbl.rx.text)
                .addDisposableTo(disposeBag)

        viewModel.exchangeRateReverted
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
