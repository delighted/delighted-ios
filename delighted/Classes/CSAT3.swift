import UIKit

class CSAT3Component: UIView, Component {
    let configuration: SurveyConfiguration
    let template: Survey.Template

    var theme: Theme {
        return configuration.theme
    }

    typealias OnSelection = (Int) -> ()
    let onSelection: OnSelection

    init(configuration: SurveyConfiguration, template: Survey.Template, onSelection: @escaping OnSelection) {
        self.configuration = configuration
        self.template = template
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

    private lazy var buttons: [UIButton] = {
        return [
            makeButton(image: Images.smileyUnhappy.image, title: template.scoreText!["1"]!),
            makeButton(image: Images.smileyNeutral.image, title: template.scoreText!["2"]!),
            makeButton(image: Images.smileyHappy.image, title: template.scoreText!["3"]!)
        ]
    }()

    private func setupView() {
        let component = ViewLayout.createCenterHorizontalStackView(subviews: buttons)
        component.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(component)
        component.alignment = .top
        NSLayoutConstraint.activate([
            component.topAnchor.constraint(equalTo: self.topAnchor),
            component.leadingAnchor.constraint(greaterThanOrEqualTo: self.leadingAnchor),
            component.trailingAnchor.constraint(lessThanOrEqualTo: self.trailingAnchor),
            component.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            component.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }

    private func makeButton(image: UIImage?, title: String) -> UIButton {
        let inactiveColor = theme.icon.inactiveBackgroundColor.color
        let activeColor = theme.icon.activeBackgroundColor.color
        let darkerActiveColor = theme.stars.activeBackgroundColor.color.darker(by: 5) ?? activeColor

        let button = TintStateButton(surveyConfiguration: configuration)
        button.setImage(image, for: .normal)
        button.setImage(image, for: .highlighted)
        button.setImage(image, for: .selected)
        button.setImage(image, for: [.selected, .highlighted])

        button.normalTintColor = inactiveColor
        button.highlightedTintColor = activeColor
        button.selectedTintColor = activeColor
        button.selectedHighlightedTintColor = darkerActiveColor

        button.isSelected = true

        button.addTarget(self, action: #selector(onSelection(sender:)), for: .touchUpInside)

        button.width(constant: 110)

        button.setTitle(title, for: .normal)
        return button
    }

    @objc func onSelection(sender: Any?) {
        Haptic.medium.generate()

        guard let buttonSelected = sender as? UIButton else {
            Logger.log(.fatal, "Could not cast selected object as a button")
            return
        }

        for button in buttons {
            button.isSelected = false
            button.setTitle(nil, for: .normal)
        }

        buttonSelected.isSelected = true

        if let index = buttons.firstIndex(of: buttonSelected) {
            // Adding 1 because CSAT will always be value of 1 to 3
            onSelection(index + 1)
        } else {
            Logger.log(.fatal, "Error getting value from selected smiley")
        }
    }
}
