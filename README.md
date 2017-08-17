## Currency exchange app 
Get current rates [from](https://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml)

Show two cyclic carousels with currencies on screen

Dependencies involved: 
* Alamofire for HTTP request
* SnapKit for AutoLayout without IB
* SWXMLHash to parse XML from ecb rates
* Swinject for DI
* RxSwift, RxCocoa, RxTest for MVVM and Rx :)

## Things to improve

* Add localisation
* Unit/UI test coverage
* Propper error handling (should notify user if something goes wrong)
* Cyclic carousel can't be used with bigger amount of views, since it won't recycle them. Beside carousel adding new currencies should be easy
* MVVM + RxSwift. I guess I'm not using Rx properly. Should change all Variables to propper Observable/Driver and use event flow instead of trying to mix imperative and FRP paradigms
