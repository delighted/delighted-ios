import UIKit

class TextArea: UIView, Component {
    typealias OnSelection = (String) -> Void
    let onSelection: OnSelection

    let configuration: SurveyConfiguration

    var theme: Theme {
        return configuration.theme
    }

    init(configuration: SurveyConfiguration, onSelection: @escaping OnSelection) {
        self.configuration = configuration
        self.onSelection = onSelection
        super.init(frame: CGRect.zero)
        setupView()
    }

    override init(frame: CGRect) {
        fatalError()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.layer.borderColor = theme.textarea.borderColor.color.cgColor
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = SurveyConfiguration.cornerRadius
        textView.font = configuration.font(ofSize: 18)
        textView.textColor = theme.textarea.textColor.color
        textView.backgroundColor = theme.textarea.backgroundColor.color
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        textView.delegate = self

        switch configuration.theme.ios.keyboardAppearance {
        case .light?:
            textView.keyboardAppearance = .light
        case .dark?:
            textView.keyboardAppearance = .dark
        case nil:
            ()
        }

        return textView
    }()

    @discardableResult
    override func becomeFirstResponder() -> Bool {
        return textView.becomeFirstResponder()
    }

    private func setupView() {
        self.addSubview(textView)

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: self.topAnchor),
            textView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 120)
        ])
    }
}

extension TextArea: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        onSelection(textView.text)
    }
}
