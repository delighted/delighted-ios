import UIKit

class OptionSelect: UIView {
    let configuration: SurveyConfiguration
    let question: Survey.Template.AdditionalQuestion
    let mode: Mode

    var buttons: [UIButton] = []

    var theme: Theme {
        return configuration.theme
    }

    typealias OnSelection = ([Survey.Template.AdditionalQuestion.Option]) -> Void
    let onSelection: OnSelection

    enum Mode {
        case single, multi
    }

    init(configuration: SurveyConfiguration, question: Survey.Template.AdditionalQuestion, mode: Mode, onSelection: @escaping OnSelection) {
        self.configuration = configuration
        self.question = question
        self.mode = mode
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

    private lazy var scrollView: UIView = {
        let view = UIScrollView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.showsVerticalScrollIndicator = false
        return view
    }()

    private lazy var directionsLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false

        switch mode {
        case .single:
            label.text = configuration.selectOneText
        case .multi:
            label.text = configuration.selectManyText
        }

        label.textColor = theme.secondaryTextColor.color
        label.font = configuration.font(ofSize: 16)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private func setupView() {
        let options = question.options ?? []
        for option in options {
            buttons.append(makeButton(title: option.text))
        }

        let component = ViewLayout.createCenterVerticalStackView(subviews: buttons, spacing: 10)
        component.translatesAutoresizingMaskIntoConstraints = false

        self.addSubview(directionsLabel)
        self.addSubview(scrollView)
        scrollView.addSubview(component)

        NSLayoutConstraint.activate([
            directionsLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            directionsLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            directionsLabel.topAnchor.constraint(equalTo: self.topAnchor),

            scrollView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: directionsLabel.bottomAnchor, constant: 10),
            scrollView.bottomAnchor.constraint(equalTo: self.bottomAnchor),

            scrollView.topAnchor.constraint(equalTo: component.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: component.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: component.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: component.bottomAnchor),

            scrollView.widthAnchor.constraint(equalTo: self.widthAnchor),
            component.widthAnchor.constraint(equalTo: self.widthAnchor)
        ])

        buttons.forEach { (button) in
            button.heightAnchor.constraint(greaterThanOrEqualToConstant: 50).isActive = true
        }
    }

    private func makeButton(title: String) -> Button {
        let button = Button(surveyConfiguration: configuration, mode: .button)
        button.translatesAutoresizingMaskIntoConstraints = false

        button.setTitle(title, for: .normal)

        button.setImage(nil, for: .normal)
        button.setImage(Images.check.templateImage, for: .selected)
        button.imageView?.contentMode = .scaleAspectFit
        button.tintColor = theme.button.activeTextColor.color

        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.translatesAutoresizingMaskIntoConstraints = false
        button.imageView?.translatesAutoresizingMaskIntoConstraints = false

        button.titleLabel?.centerYAnchor.constraint(equalTo: button.centerYAnchor).isActive = true

        // Adjusts content edge insets to allow for the checkmark image to not overlap with the title
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 50, bottom: 8, right: 50)

        button.imageView?.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -16.0).isActive = true
        button.imageView?.centerYAnchor.constraint(equalTo: button.centerYAnchor, constant: 0.0).isActive = true
        button.imageView?.heightAnchor.constraint(equalToConstant: 20).isActive = true
        button.imageView?.widthAnchor.constraint(equalToConstant: 20).isActive = true

        button.titleLabel?.trailingAnchor.constraint(lessThanOrEqualTo: button.imageView!.leadingAnchor, constant: -10).isActive = true
        button.titleLabel?.textAlignment = .center

        switch mode {
        case .single:
            button.addTarget(self, action: #selector(onSelectSingle(sender:)), for: .touchUpInside)
        case .multi:
            button.addTarget(self, action: #selector(onSelectMulti(sender:)), for: .touchUpInside)
        }

        return button
    }

    private func callbackSelected() {
        let options = buttons.filter { (button) -> Bool in
            return button.isSelected
        }.compactMap { (button) -> Int? in
            return buttons.firstIndex(of: button)
        }.compactMap { (index) -> Survey.Template.AdditionalQuestion.Option? in
            return question.options?[index]
        }

        onSelection(options)
    }

    @objc func onSelectSingle(sender: Any?) {
        guard let button = sender as? UIButton else {
            return
        }

        UIView.transition(with: button, duration: 0.2, options: .transitionCrossDissolve, animations: { [unowned self] in
            self.buttons.forEach { (button) in
                button.isSelected = false
            }
            button.isSelected = !button.isSelected
        }, completion: { [unowned self] (_) in
            self.callbackSelected()
        })
    }

    @objc func onSelectMulti(sender: Any?) {
        guard let button = sender as? UIButton else {
            return
        }

        UIView.transition(with: button, duration: 0.2, options: .transitionCrossDissolve, animations: {
            button.isSelected = !button.isSelected
        }, completion: { [unowned self] (_) in
            self.callbackSelected()
        })
    }
}
