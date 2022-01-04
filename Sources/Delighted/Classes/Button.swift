import UIKit

class TintStateButton: UIButton {
    let labelPaddingTop: CGFloat = 8.0
    let surveyConfiguration: SurveyConfiguration

    var theme: Theme {
        return surveyConfiguration.theme
    }

    var normalTintColor: UIColor? = nil {
            didSet {
                updateTint()
            }
        }
    var selectedTintColor: UIColor? = nil {
           didSet {
               updateTint()
           }
       }
    var highlightedTintColor: UIColor? = nil {
           didSet {
               updateTint()
           }
       }
    var selectedHighlightedTintColor: UIColor? = nil {
           didSet {
               updateTint()
           }
       }

    init(surveyConfiguration: SurveyConfiguration) {
        self.surveyConfiguration = surveyConfiguration
        super.init(frame: .zero)

        apply()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isSelected: Bool {
        willSet {
            super.isSelected = newValue
            updateTint()
        }
    }

    override var isHighlighted: Bool {
        willSet {
            super.isHighlighted = newValue
            updateTint()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if let title = currentTitle {
            // Resize the content area to be large enough for the label, place
            // the label beneath the image, and center-align the content.
            let buttonWidth = frame.size.width
            let imageHeight = currentImage!.size.height
            let imageWidth = currentImage!.size.width

            titleLabel!.numberOfLines = 0
            let labelHeight = textHeight(text: title, withWidth: buttonWidth, font: titleLabel!.font)

            contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: labelHeight + labelPaddingTop, right: 0)
            imageEdgeInsets = UIEdgeInsets(top: 0, left: (bounds.width - imageWidth) / 2, bottom: 0, right: 0)
            titleEdgeInsets = UIEdgeInsets(top: imageHeight + labelHeight + labelPaddingTop, left: -imageWidth, bottom: -labelPaddingTop, right: 0)
        } else {
            contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
    }

    private func updateTint() {
        switch (isSelected, isHighlighted) {
        case (false, false):
            tintColor = normalTintColor
        case (false, true):
            tintColor = highlightedTintColor
        case (true, false):
            tintColor = selectedTintColor
        case (true, true):
            tintColor = selectedHighlightedTintColor
        }
    }

    private func apply() {
        layer.masksToBounds = true
        titleLabel?.textAlignment = .center
        titleLabel?.font = surveyConfiguration.font(ofSize: 14)

        setTitleColor(theme.primaryTextColor.color, for: .normal)
        setTitleColor(theme.primaryTextColor.color, for: [.normal, .highlighted])
        setTitleColor(theme.primaryTextColor.color, for: .selected)
        setTitleColor(theme.primaryTextColor.color, for: [.selected, .highlighted])
    }

    private func textHeight(text: String, withWidth width: CGFloat, font: UIFont) -> CGFloat {
        let maxSize = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        let actualSize = text.boundingRect(with: maxSize, options: [.usesLineFragmentOrigin], attributes: [.font: font], context: nil)
        return actualSize.height
    }
}

class Button: UIButton {

    let surveyConfiguration: SurveyConfiguration
    let mode: Mode

    var theme: Theme {
        return surveyConfiguration.theme
    }

    enum Mode {
        case primary, secondary, scale, button
    }

    init(surveyConfiguration: SurveyConfiguration, mode: Mode) {
        self.surveyConfiguration = surveyConfiguration
        self.mode = mode
        super.init(frame: .zero)

        self.titleLabel?.numberOfLines = 0
        self.titleLabel?.textAlignment = .center
        self.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)

        apply()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        switch theme.buttonShape {
        case .circle:
            layer.cornerRadius = bounds.height / 2.0
        case .roundRect:
            layer.cornerRadius = SurveyConfiguration.cornerRadius
        case .square:
            layer.cornerRadius = 0
        }

        switch mode {
        case .primary:
            ()
        case .secondary:
            ()
        case .scale:
            layer.borderWidth = 1
            addTarget(self, action: #selector(onTouchUp), for: .touchUpInside)
            switch (isSelected, isHighlighted) {
            case (false, false):
                layer.borderColor = theme.scale.inactiveBorderColor.color.cgColor
            case (false, true):
                layer.borderColor = theme.scale.activeBorderColor.color.cgColor
            case (true, false):
                layer.borderColor = theme.scale.activeBorderColor.color.cgColor
            case (true, true):
                layer.borderColor = theme.scale.activeBorderColor.color.cgColor
            }
        case .button:
            layer.borderWidth = 1
            addTarget(self, action: #selector(onTouchUp), for: .touchUpInside)
            switch (isSelected, isHighlighted) {
            case (false, false):
                layer.borderColor = theme.button.inactiveBorderColor.color.cgColor
            case (false, true):
                layer.borderColor = theme.button.activeBorderColor.color.cgColor
            case (true, false):
                layer.borderColor = theme.button.activeBorderColor.color.cgColor
            case (true, true):
                layer.borderColor = theme.button.inactiveBorderColor.color.cgColor
            }
        }
    }

    // Listens for changes and adjusts the inset constraints
    override var contentEdgeInsets: UIEdgeInsets {
        get {
            return super.contentEdgeInsets
        }
        set {
            topInsetConstraint?.constant = newValue.top
            bottomInsetConstraint?.constant = -newValue.bottom
            leftInsetConstraint?.constant = newValue.left
            rightInsetConstraint?.constant = -newValue.right
            super.contentEdgeInsets = newValue
        }
    }

    private lazy var topInsetConstraint: NSLayoutConstraint? = {
        return titleLabel?.topAnchor.constraint(equalTo: topAnchor, constant: 0)
    }()

    private lazy var bottomInsetConstraint: NSLayoutConstraint? = {
        return titleLabel?.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0)
    }()

    private lazy var leftInsetConstraint: NSLayoutConstraint? = {
        return titleLabel?.leftAnchor.constraint(equalTo: leftAnchor, constant: 0)
    }()

    private lazy var rightInsetConstraint: NSLayoutConstraint? = {
        return titleLabel?.rightAnchor.constraint(equalTo: rightAnchor, constant: 0)
    }()

    @objc func onTouchUp(sender: Any?) {
        Haptic.medium.generate()
    }

    private func apply() {
        // Sets inset constraints that allow the button to
        // grow with titel label size
        topInsetConstraint?.isActive = true
        bottomInsetConstraint?.isActive = true
        leftInsetConstraint?.isActive = true
        rightInsetConstraint?.isActive = true

        layer.masksToBounds = true
        titleLabel?.font = surveyConfiguration.font(ofSize: 16)

        let titleColorNormal: UIColor
        let titleColorHightlighted: UIColor?
        let titleColorSelected: UIColor?
        let titleColorSelectedHightlighted: UIColor?
        let backgroundImageNormal: UIImage?
        let backgroundImageSelected: UIImage?
        let backgroundImageHighlighted: UIImage?
        let backgroundImageSelectedHighlighted: UIImage?
        let borderWidth: CGFloat
        let borderColor: UIColor

        switch mode {
        case .primary:
            titleColorNormal = theme.primaryButton.textColor.color
            titleColorHightlighted = nil
            titleColorSelected = nil
            titleColorSelectedHightlighted = nil
            backgroundImageNormal = theme.primaryButton.backgroundColor.color.asImage
            backgroundImageHighlighted = theme.primaryButton.backgroundColor.color.darker(by: 10)?.asImage
            backgroundImageSelected = nil
            backgroundImageSelectedHighlighted = nil

            borderWidth = 1
            borderColor = theme.primaryButton.borderColor.color
        case .secondary:
            titleColorNormal = theme.secondaryButton.textColor.color
            titleColorHightlighted = nil
            titleColorSelected = nil
            titleColorSelectedHightlighted = nil
            backgroundImageNormal = theme.secondaryButton.backgroundColor.color.asImage
            backgroundImageHighlighted = theme.secondaryButton.backgroundColor.color.darker(by: 10)?.asImage
            backgroundImageSelected = nil
            backgroundImageSelectedHighlighted = nil

            borderWidth = 1
            borderColor = theme.secondaryButton.borderColor.color
        case .scale:
            titleColorNormal = theme.scale.inactiveTextColor.color
            titleColorHightlighted = theme.scale.activeTextColor.color
            titleColorSelected = theme.scale.activeTextColor.color
            titleColorSelectedHightlighted = theme.scale.inactiveTextColor.color
            backgroundImageNormal = theme.scale.inactiveBackgroundColor.color.asImage
            backgroundImageHighlighted = theme.scale.activeBackgroundColor.color.asImage
            backgroundImageSelected = theme.scale.activeBackgroundColor.color.asImage
            backgroundImageSelectedHighlighted = theme.scale.activeBackgroundColor.color.darker(by: 5)?.asImage

            borderWidth = 1
            borderColor = theme.scale.inactiveBorderColor.color
        case .button:
            titleColorNormal = theme.button.inactiveTextColor.color
            titleColorHightlighted = theme.button.activeTextColor.color
            titleColorSelected = theme.button.activeTextColor.color
            titleColorSelectedHightlighted = theme.button.inactiveTextColor.color
            backgroundImageNormal = theme.button.inactiveBackgroundColor.color.asImage
            backgroundImageHighlighted = theme.button.activeBackgroundColor.color.asImage
            backgroundImageSelected = theme.button.activeBackgroundColor.color.asImage
            backgroundImageSelectedHighlighted = theme.button.inactiveBackgroundColor.color.asImage

            borderWidth = 1
            borderColor = theme.button.inactiveBorderColor.color
        }

        setTitleColor(titleColorNormal, for: .normal)
        setTitleColor(titleColorHightlighted, for: [.normal, .highlighted])
        setTitleColor(titleColorSelected, for: .selected)
        setTitleColor(titleColorSelectedHightlighted, for: [.selected, .highlighted])
        setBackgroundImage(backgroundImageNormal, for: .normal)
        setBackgroundImage(backgroundImageHighlighted, for: [.normal, .highlighted])
        setBackgroundImage(backgroundImageSelected, for: .selected)
        setBackgroundImage(backgroundImageSelectedHighlighted, for: [.selected, .highlighted])

        layer.borderWidth = borderWidth
        layer.borderColor = borderColor.cgColor
    }
}
