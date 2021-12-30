import UIKit

public struct Theme: Decodable {
    let display: Display
    let containerCornerRadius: CGFloat
    let primaryColor: Color
    let buttonStyle: ThemeStyle
    let buttonShape: ThemeShape
    let backgroundColor: Color
    let primaryTextColor: Color
    let secondaryTextColor: Color
    let textarea: TextArea
    let primaryButton: PrimaryButton
    let secondaryButton: SecondaryButton
    let button: Button
    let stars: Stars
    let icon: Icon
    let scale: Scale
    let slider: Slider
    let closeButton: CloseButton
    let ios: IOS

    public init(display: Display, containerCornerRadius: CGFloat, primaryColor: UIColor, buttonStyle: ThemeStyle,
                buttonShape: ThemeShape, backgroundColor: UIColor, primaryTextColor: UIColor,
                secondaryTextColor: UIColor, textarea: TextArea, primaryButton: PrimaryButton,
                secondaryButton: SecondaryButton, button: Button, stars: Stars, icon: Icon, scale: Scale,
                slider: Slider, closeButton: CloseButton, ios: IOS) {
        self.display = display
        self.containerCornerRadius = containerCornerRadius
        self.primaryColor = Color(color: primaryColor)
        self.buttonStyle = buttonStyle
        self.buttonShape = buttonShape
        self.backgroundColor = Color(color: backgroundColor)
        self.primaryTextColor = Color(color: primaryTextColor)
        self.secondaryTextColor = Color(color: secondaryTextColor)
        self.textarea = textarea
        self.primaryButton = primaryButton
        self.secondaryButton = secondaryButton
        self.button = button
        self.stars = stars
        self.icon = icon
        self.scale = scale
        self.slider = slider
        self.closeButton = closeButton
        self.ios = ios
    }

    public struct TextArea: Decodable {
        let backgroundColor: Color
        let textColor: Color
        let borderColor: Color

        public init(backgroundColor: UIColor, textColor: UIColor, borderColor: UIColor) {
            self.backgroundColor = Color(color: backgroundColor)
            self.textColor = Color(color: textColor)
            self.borderColor = Color(color: borderColor)
        }
    }

    public struct PrimaryButton: Decodable {
        let backgroundColor: Color
        let textColor: Color
        let borderColor: Color

        public init(backgroundColor: UIColor, textColor: UIColor, borderColor: UIColor) {
            self.backgroundColor = Color(color: backgroundColor)
            self.textColor = Color(color: textColor)
            self.borderColor = Color(color: borderColor)
        }
    }

    public struct SecondaryButton: Decodable {
        let backgroundColor: Color
        let textColor: Color
        let borderColor: Color

        public init(backgroundColor: UIColor, textColor: UIColor, borderColor: UIColor) {
            self.backgroundColor = Color(color: backgroundColor)
            self.textColor = Color(color: textColor)
            self.borderColor = Color(color: borderColor)
        }
    }

    public struct Button: Decodable {
        let activeBackgroundColor: Color
        let activeTextColor: Color
        let activeBorderColor: Color
        let inactiveBackgroundColor: Color
        let inactiveTextColor: Color
        let inactiveBorderColor: Color

        public init(activeBackgroundColor: UIColor, activeTextColor: UIColor, activeBorderColor: UIColor,
                    inactiveBackgroundColor: UIColor, inactiveTextColor: UIColor, inactiveBorderColor: UIColor) {
            self.activeBackgroundColor = Color(color: activeBackgroundColor)
            self.activeTextColor = Color(color: activeTextColor)
            self.activeBorderColor = Color(color: activeBorderColor)
            self.inactiveBackgroundColor = Color(color: inactiveBackgroundColor)
            self.inactiveTextColor = Color(color: inactiveTextColor)
            self.inactiveBorderColor = Color(color: inactiveBorderColor)
        }
    }

    public struct Stars: Decodable {
        let activeBackgroundColor: Color
        let inactiveBackgroundColor: Color

        public init(activeBackgroundColor: UIColor, inactiveBackgroundColor: UIColor) {
            self.activeBackgroundColor = Color(color: activeBackgroundColor)
            self.inactiveBackgroundColor = Color(color: inactiveBackgroundColor)
        }
    }

    public struct Icon: Decodable {
        let activeBackgroundColor: Color
        let inactiveBackgroundColor: Color

        public init(activeBackgroundColor: UIColor, inactiveBackgroundColor: UIColor) {
            self.activeBackgroundColor = Color(color: activeBackgroundColor)
            self.inactiveBackgroundColor = Color(color: inactiveBackgroundColor)
        }
    }

    public struct Scale: Decodable {
        let activeBackgroundColor: Color
        let activeTextColor: Color
        let activeBorderColor: Color
        let inactiveBackgroundColor: Color
        let inactiveTextColor: Color
        let inactiveBorderColor: Color

        public init(activeBackgroundColor: UIColor, activeTextColor: UIColor, activeBorderColor: UIColor,
                    inactiveBackgroundColor: UIColor, inactiveTextColor: UIColor, inactiveBorderColor: UIColor) {
            self.activeBackgroundColor = Color(color: activeBackgroundColor)
            self.activeTextColor = Color(color: activeTextColor)
            self.activeBorderColor = Color(color: activeBorderColor)
            self.inactiveBackgroundColor = Color(color: inactiveBackgroundColor)
            self.inactiveTextColor = Color(color: inactiveTextColor)
            self.inactiveBorderColor = Color(color: inactiveBorderColor)
        }
    }

    public struct Slider: Decodable {
        let knobBackgroundColor: Color
        let knobTextColor: Color
        let knobBorderColor: Color
        let trackActiveColor: Color
        let trackInactiveColor: Color
        let hoverBackgroundColor: Color
        let hoverTextColor: Color
        let hoverBorderColor: Color

        public init(knobBackgroundColor: UIColor, knobTextColor: UIColor, knobBorderColor: UIColor,
                    trackActiveColor: UIColor, trackInactiveColor: UIColor, hoverBackgroundColor: UIColor, hoverTextColor: UIColor, hoverBorderColor: UIColor) {
            self.knobBackgroundColor = Color(color: knobBackgroundColor)
            self.knobTextColor = Color(color: knobTextColor)
            self.knobBorderColor = Color(color: knobBorderColor)
            self.trackActiveColor = Color(color: trackActiveColor)
            self.trackInactiveColor = Color(color: trackInactiveColor)
            self.hoverBackgroundColor = Color(color: hoverBackgroundColor)
            self.hoverTextColor = Color(color: hoverTextColor)
            self.hoverBorderColor = Color(color: hoverBorderColor)
        }
    }

    public struct CloseButton: Decodable {
        let normalBackgroundColor: Color
        let normalTextColor: Color
        let normalBorderColor: Color
        let highlightedBackgroundColor: Color
        let highlightedTextColor: Color
        let highlightedBorderColor: Color

        public init(normalBackgroundColor: UIColor, normalTextColor: UIColor, normalBorderColor: UIColor,
                    highlightedBackgroundColor: UIColor, highlightedTextColor: UIColor, highlightedBorderColor: UIColor) {
            self.normalBackgroundColor = Color(color: normalBackgroundColor)
            self.normalTextColor = Color(color: normalTextColor)
            self.normalBorderColor = Color(color: normalBorderColor)
            self.highlightedBackgroundColor = Color(color: highlightedBackgroundColor)
            self.highlightedTextColor = Color(color: highlightedTextColor)
            self.highlightedBorderColor = Color(color: highlightedBorderColor)
        }
    }

    public struct IOS: Decodable {
        public enum KeyboardAppearance: String, Decodable {
            case light, dark
        }
        public enum StatusBarMode: String, Decodable {
            case lightContent = "light_content", darkContent = "dark_content"
        }

        let keyboardAppearance: KeyboardAppearance?
        let statusBarMode: StatusBarMode?
        let statusBarHidden: Bool?

        public init(keyboardAppearance: KeyboardAppearance? = nil, statusBarMode: StatusBarMode?, statusBarHidden: Bool?) {
            self.keyboardAppearance = keyboardAppearance
            self.statusBarMode = statusBarMode
            self.statusBarHidden = statusBarHidden
        }

        enum CodingKeys: CodingKey {
            case keyboardAppearance, statusBarMode, statusBarHidden
        }
    }

    public struct Color {
        let color: UIColor

        init(color: UIColor) {
            self.color = color
        }
     }
}

extension Theme.Color: Decodable {
    enum CodingKeys: CodingKey {
        case color
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let hexString = try container.decode(String.self)
        self.color = UIColor(hex: hexString)
    }
}
