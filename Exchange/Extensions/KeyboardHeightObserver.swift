import RxSwift
import RxCocoa

func keyboardHeight() -> Observable<CGFloat> {
    return Observable
            .from([
                    NotificationCenter.default.rx.notification(NSNotification.Name.UIKeyboardWillShow)
                            .map { notification -> CGFloat in
                                (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?
                                        .cgRectValue.height ?? 0
                            },
                    NotificationCenter.default.rx.notification(NSNotification.Name.UIKeyboardWillHide)
                            .map { _ -> CGFloat in
                                0
                            }
            ])
            .merge()
}
