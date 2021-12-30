import UIKit

class ThumbsComponent: UIView, Component {
    let configuration: SurveyConfiguration

    var theme: Theme {
        return configuration.theme
    }

    typealias OnSelection = (Int) -> Void
    let onSelection: OnSelection

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

    private lazy var thumbsUpButton: UIButton = {
        return makeButton(image: Images.thumbsUp.image)
    }()

    private lazy var thumbsDownButton: UIButton = {
        return makeButton(image: Images.thumbsDown.image)
    }()

    private lazy var buttons: [UIButton] = {
        return [thumbsUpButton, thumbsDownButton]
    }()

    private func setupView() {
        let component = ViewLayout.createCenterHorizontalStackView(subviews: buttons, spacing: 15)
        component.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(component)

        NSLayoutConstraint.activate([
            component.topAnchor.constraint(equalTo: self.topAnchor),
            component.leadingAnchor.constraint(greaterThanOrEqualTo: self.leadingAnchor),
            component.trailingAnchor.constraint(lessThanOrEqualTo: self.trailingAnchor),
            component.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            component.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }

    private func makeButton(image: UIImage?) -> UIButton {
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

        button.width(constant: 55)
        button.height(constant: 55)

        return button
    }

    @objc func onSelection(sender: Any?) {
        Haptic.medium.generate()

        for button in buttons {
            button.isSelected = false
        }

        let button = sender as? UIButton
        button?.isSelected = true

        switch button {
        case thumbsUpButton:
            onSelection(1)
        case thumbsDownButton:
            onSelection(0)
        default:
            ()
        }
    }
}
