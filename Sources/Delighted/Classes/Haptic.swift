import UIKit

enum Haptic {
    case light, medium, heavy
}

extension Haptic {
    func generate() {
        if #available(iOS 10.0, *) {
            var style: UIImpactFeedbackGenerator.FeedbackStyle {
                switch self {
                case .light:
                    return .light
                case .medium:
                    return .medium
                case .heavy:
                    return .heavy
                }
            }

            let generator = UIImpactFeedbackGenerator(style: style)
            generator.impactOccurred()
        }
    }
}
