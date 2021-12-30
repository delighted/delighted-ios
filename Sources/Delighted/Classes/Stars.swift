import UIKit

class StarsComponent: UIView, Component {
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

    private lazy var buttons: [UIButton] = {
        return [
            makeButton(),
            makeButton(),
            makeButton(),
            makeButton(),
            makeButton()
        ]
    }()

    private func setupView() {
        let component = ViewLayout.createCenterHorizontalStackView(subviews: buttons)
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

    private func makeButton() -> UIButton {
        let inactiveColor = theme.stars.inactiveBackgroundColor.color
        let activeColor = theme.stars.activeBackgroundColor.color
        let darkerActiveColor = theme.stars.activeBackgroundColor.color.darker(by: 5) ?? activeColor

        let button = TintStateButton(surveyConfiguration: configuration)
        let selectedImage = Images.star.image

        switch theme.buttonStyle {
        case .solid:
            let image = Images.star.image
            button.setImage(image, for: .normal)
            button.setImage(selectedImage, for: .highlighted)
            button.setImage(selectedImage, for: .selected)
            button.setImage(selectedImage, for: [.selected, .highlighted])

            button.normalTintColor = inactiveColor
            button.highlightedTintColor = activeColor
            button.selectedTintColor = activeColor
            button.selectedHighlightedTintColor = darkerActiveColor
        case .outline:
            let image = Images.starOutline.image
            button.setImage(image, for: .normal)
            button.setImage(selectedImage, for: .highlighted)
            button.setImage(selectedImage, for: .selected)
            button.setImage(selectedImage, for: [.selected, .highlighted])

            button.normalTintColor = inactiveColor
            button.highlightedTintColor = activeColor
            button.selectedTintColor = activeColor
            button.selectedHighlightedTintColor = darkerActiveColor
        }

        button.addTarget(self, action: #selector(onSelection(sender:)), for: .touchUpInside)
        button.addTarget(self, action: #selector(highlightStars(sender:)), for: .touchDown)
        button.addTarget(self, action: #selector(unHighlightAll(sender:)), for: .touchUpOutside)
        button.addTarget(self, action: #selector(unHighlightAll(sender:)), for: .touchDragExit)
        button.addTarget(self, action: #selector(highlightStars), for: .touchDragEnter)
        button.addTarget(self, action: #selector(highlightStars), for: .touchDragInside)

        button.width(constant: 55)
        button.height(constant: 55)

        return button
    }

    @objc func highlightStars(sender: Any?) {
        guard let buttonSelected = sender as? UIButton else {
            Logger.log(.fatal, "Could not cast selected object as a button")
            return
        }

        var highlight = true
        for button in buttons {
            button.isHighlighted = highlight
            if button == buttonSelected {
                highlight = false
            }
        }
    }

    @objc func unHighlightAll(sender: Any?) {
        for button in buttons {
            button.isHighlighted = false
        }
    }

    @objc func onSelection(sender: Any?) {
        Haptic.medium.generate()

        guard let buttonSelected = sender as? UIButton else {
            Logger.log(.fatal, "Could not cast selected object as a button")
            return
        }

        var selected = true
        for button in buttons {
            button.isSelected = selected

            if button == buttonSelected {
                selected = false
            }
        }

        if let index = buttons.firstIndex(of: buttonSelected) {
            // Adding 1 because stars will always be value of 1 to 5
            let value = index + 1
            onSelection(value)
        } else {
            Logger.log(.fatal, "Error getting value from selected star")
        }
    }
}
