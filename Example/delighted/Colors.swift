import UIKit

extension UIColor {
    convenience init(hex: String) {
        // https://stackoverflow.com/a/33397427/2464643
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt32()
        Scanner(string: hex).scanHexInt32(&int)
        let a, r, g, b: UInt32
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}

struct LocalThemeColors {
    static let primaryColor = UIColor(hex: "05DC88")
    static let white = UIColor.white // alias in case we want to slightly tweak it
    static let gray = UIColor(hex: "9C9FA1")
    static let grayDark = UIColor(hex: "787A7E")
    static let grayDarker = UIColor(hex: "2B3239")
    static let grayDarkest = UIColor(hex: "0A1016")
    static let black = UIColor(hex: "081118")
}
