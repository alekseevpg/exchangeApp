import Foundation
import UIKit
import SnapKit
import RxSwift
import RxCocoa

class CurrencyScrollView: UIView {
    var disposeBag = DisposeBag()
    var viewModel: CurrencyScrollViewModel!

    lazy var scrollView = UIScrollView()
    lazy var pageControl = UIPageControl()
    lazy var contentView = UIView()
    private lazy var shadedLayer = ShadedLayer()

    private var isShaded: Bool = false

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    init(viewModel: CurrencyScrollViewModel, shaded: Bool = false) {
        super.init(frame: .zero)
        self.isShaded = shaded
        self.viewModel = viewModel
        self.createViews()
        self.setupConstraints()
        self.bindModel()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateFrame()
    }

    private func bindModel() {
        scrollView.rx.didEndDecelerating.subscribe(onNext: { _ in
            let width = self.bounds.width
            let height = self.bounds.height
            let offset = self.scrollView.contentOffset
            if (offset.x == 0) {
                self.scrollView.scrollRectToVisible(CGRect(x: CGFloat(self.viewModel.items.count) * width, y: 0,
                        width: width, height: height), animated: false)
                self.viewModel.currentIndex.value = self.viewModel.items.count - 1
            } else if (offset.x == CGFloat(self.viewModel.items.count + 1) * width) {
                self.scrollView.scrollRectToVisible(CGRect(x: width, y: 0,
                        width: width, height: height), animated: false)
                self.viewModel.currentIndex.value = 0
            } else {
                let page = Int((offset.x) / width)
                self.viewModel.currentIndex.value = page - 1
            }
        }).disposed(by: disposeBag)

        viewModel.currentIndex.asObservable()
                .bind(to: pageControl.rx.currentPage)
                .addDisposableTo(disposeBag)
        viewModel.currentIndex.value = 0
    }

    private func createViews() {
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        addSubview(scrollView)

        scrollView.addSubview(contentView)

        addSubview(pageControl)
        pageControl.numberOfPages = viewModel.items.count
        pageControl.isUserInteractionEnabled = false

        var firstItem = createCurrencyView(type: viewModel.items.last!, leading: contentView.snp.leading)
        for item in viewModel.items {
            let newLbl = createCurrencyView(type: item, leading: firstItem.snp.trailing)
            firstItem = newLbl
        }
        let lastLbl = createCurrencyView(type: viewModel.items.first!, leading: firstItem.snp.trailing)

        if isShaded {
            self.layer.addSublayer(shadedLayer)
        }
    }

    private func setupConstraints() {
        scrollView.snp.makeConstraints({ make in
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
        })
        contentView.snp.makeConstraints({ make in
            make.top.equalToSuperview()
            make.height.equalToSuperview()
            make.leading.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(viewModel.items.count + 2)
        })
        pageControl.snp.makeConstraints({ make in
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(40)
        })
    }

    func updateFrame() {
        if isShaded {
            shadedLayer.frame = self.bounds
        }
        scrollView.contentSize = CGSize(width: contentView.frame.width, height: frame.height)
        scrollView.scrollRectToVisible(CGRect(x: frame.width * CGFloat(viewModel.currentIndex.value + 1), y: 0,
                width: frame.width, height: frame.height), animated: false)
    }

    private func createCurrencyView(type: CurrencyType, leading: ConstraintRelatableTarget) -> CurrencyView {
        let newLbl = CurrencyView()
        newLbl.titleLbl.text = type.rawValue
        contentView.addSubview(newLbl)
        newLbl.snp.makeConstraints({ make in
            make.leading.equalTo(leading)
            make.width.equalTo(snp.width)
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
        })

        viewModel.sufficientFundsToExchange.asObservable()
                .map({ $0 ? UIColor.white : UIColor.red })
                .bind(to: newLbl.amountLbl.rx.textColor)
                .addDisposableTo(disposeBag)

        viewModel.storage[type]!.asObservable()
                .map({ "You have \(type.toSign())\($0.toString())" })
                .bind(to: newLbl.amountLbl.rx.text)
                .addDisposableTo(disposeBag)
        return newLbl
    }
}
