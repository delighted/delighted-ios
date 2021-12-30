import UIKit

enum Images: String {

    case check = "check"

    case x = "x"
    case close = "close"
    case star = "star"
    case starOutline = "star_outline"

    case smileyVeryUnhappy = "smilies_very_unhappy"
    case smileyUnhappy = "smilies_unhappy"
    case smileyNeutral = "smilies_neutral"
    case smileyHappy = "smilies_happy"
    case smileyVeryHappy = "smilies_very_happy"
    case smileyVeryDisappointed = "smilies_very_disappointed"

    case thumbsUp = "thumbs_up"
    case thumbsDown = "thumbs_down"

    var image: UIImage? {
        return UIImage(named: rawValue, in: DelightedResources.resourceBundle, compatibleWith: nil)
    }

    var templateImage: UIImage? {
        return image?.withRenderingMode(.alwaysTemplate)
    }
}

private final class DelightedResources {
    public static let resourceBundle: Bundle = {
        let candidates = [
            // Bundle should be present here when the package is linked into an App.
            Bundle.main.resourceURL,
            // Bundle should be present here when the package is linked into a framework.
            Bundle(for: DelightedResources.self).resourceURL
        ]

        let bundleName = "Delighted_Delighted"

        for candidate in candidates {
            let bundlePath = candidate?.appendingPathComponent(bundleName + ".bundle")
            Logger.log(.debug, "Looking for bundle at \(String(describing: bundlePath))")
            if let bundle = bundlePath.flatMap(Bundle.init(url:)) {
                return bundle
            }
        }

        // Return whatever bundle this code is in as a last resort.
        return Bundle(for: DelightedResources.self)
    }()
}
