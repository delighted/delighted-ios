import UIKit

public enum Display: String, Decodable {
    case card, modal
}

public enum TextBaseDirection: String, Decodable {
    case ltr, rtl
}

public enum ThemeStyle: String, Decodable {
    case outline, solid
}

public enum ThemeShape: String, Decodable {
    case circle, roundRect = "round_rect", square
}

public class Options: NSObject {
    // From API
    var textBaseDirection: TextBaseDirection?

    var poweredByLinkText: String?
    var poweredByLinkURL: String?

    var nextText: String?
    var prevText: String?

    var selectOneText: String?
    var selectManyText: String?

    var submitText: String?
    var doneText: String?

    var notLikelyText: String?
    var veryLikelyText: String?

    var theme: Theme?

    // From developer
    var modalMargin: CGFloat
    var baseURL: URL?
    var cdnURL: URL?
    var fontFamilyName: String?
    var thankYouAutoCloseDelay: Int?

    public init(
        textBaseDirection: TextBaseDirection? = nil,
        poweredByLinkText: String? = nil,
        poweredByLinkURL: String? = nil,
        nextText: String? = nil,
        prevText: String? = nil,
        selectOneText: String? = nil,
        selectManyText: String? = nil,
        submitText: String? = nil,
        doneText: String? = nil,
        notLikelyText: String? = nil,
        veryLikelyText: String? = nil,
        theme: Theme? = nil,
        modalMargin: CGFloat = 10,
        baseURL: URL? = nil,
        cdnURL: URL? = nil,
        fontFamilyName: String? = nil,
        thankYouAutoCloseDelay: Int? = nil
        ) {
        // From API
        self.textBaseDirection = textBaseDirection
        self.poweredByLinkText = poweredByLinkText
        self.poweredByLinkURL = poweredByLinkURL
        self.nextText = nextText
        self.prevText = prevText
        self.selectOneText = selectOneText
        self.selectManyText = selectManyText
        self.submitText = submitText
        self.doneText = doneText
        self.notLikelyText = notLikelyText
        self.veryLikelyText = veryLikelyText
        self.theme = theme

        // From developer
        self.modalMargin = modalMargin
        self.baseURL = baseURL
        self.cdnURL = cdnURL
        self.fontFamilyName = fontFamilyName
        self.thankYouAutoCloseDelay = thankYouAutoCloseDelay
    }
}

public struct SurveyConfiguration {
    static let cornerRadius: CGFloat = 8.0

    // From API
    var textBaseDirection: TextBaseDirection

    var poweredByLinkText: String
    var poweredByLinkURL: String

    var nextText: String
    var prevText: String

    var selectOneText: String
    var selectManyText: String

    var submitText: String
    var doneText: String

    var notLikelyText: String
    var veryLikelyText: String

    let pusher: Pusher

    var theme: Theme

    // From developer
    var display: Display = .card
    var modalMargin: CGFloat = 10
    var baseURL: URL?
    var cdnURL: URL?
    var fontFamilyName: String = UIFont.systemFont(ofSize: 1).familyName
    var thankYouAutoCloseDelay: Int?

    mutating func applyOptions(options: Options?) {
        guard let options = options else { return }

        // From API
        textBaseDirection = options.textBaseDirection ?? textBaseDirection

        poweredByLinkText = options.poweredByLinkText ?? poweredByLinkText
        poweredByLinkURL = options.poweredByLinkURL ?? poweredByLinkURL

        nextText = options.nextText ?? nextText
        prevText = options.prevText ?? prevText

        selectOneText = options.selectOneText ?? selectOneText
        selectManyText = options.selectManyText ?? selectManyText

        submitText = options.submitText ?? submitText
        doneText = options.doneText ?? doneText

        notLikelyText = options.notLikelyText ?? notLikelyText
        veryLikelyText = options.veryLikelyText ?? veryLikelyText

        self.theme = options.theme ?? theme

        // From developer
        self.modalMargin = options.modalMargin
        self.baseURL = options.baseURL ?? baseURL
        self.cdnURL = options.cdnURL ?? cdnURL
        self.fontFamilyName = options.fontFamilyName ?? fontFamilyName
        self.thankYouAutoCloseDelay = options.thankYouAutoCloseDelay
    }

    struct Pusher: Decodable {
        let webSocketUrl: String?
        let channelName: String?
        let enabled: Bool
    }
}

extension SurveyConfiguration: Decodable {
    enum CodingKeys: CodingKey {
        case textBaseDirection, poweredByLinkText, poweredByLinkUrl,
        nextText, prevText, selectOneText, selectManyText,
        submitText, doneText, notLikelyText, veryLikelyText,
        pusher,
        themeColorPrimary, themeColorStars, themeStyle, themeShape,
        theme
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.textBaseDirection = try container.decode(TextBaseDirection.self, forKey: .textBaseDirection)

        self.poweredByLinkText = try container.decode(String.self, forKey: .poweredByLinkText)
        self.poweredByLinkURL = try container.decode(String.self, forKey: .poweredByLinkUrl)

        self.nextText = try container.decode(String.self, forKey: .nextText)
        self.prevText = try container.decode(String.self, forKey: .prevText)

        self.selectOneText = try container.decode(String.self, forKey: .selectOneText)
        self.selectManyText = try container.decode(String.self, forKey: .selectManyText)

        self.submitText = try container.decode(String.self, forKey: .submitText)
        self.doneText = try container.decode(String.self, forKey: .doneText)

        self.notLikelyText = try container.decode(String.self, forKey: .notLikelyText)
        self.veryLikelyText = try container.decode(String.self, forKey: .veryLikelyText)

        self.pusher = try container.decode(Pusher.self, forKey: .pusher)

        self.theme = try container.decode(Theme.self, forKey: .theme)
    }
}

extension SurveyConfiguration {
    func font(ofSize: CGFloat) -> UIFont {
        return UIFont(name: fontFamilyName, size: ofSize) ?? UIFont.systemFont(ofSize: ofSize)
    }
}
