import Foundation

public struct ThankYou: Decodable {
    let text: String
    let autoCloseDelay: Int?
    let groups: [Group]

    enum CodingKeys: CodingKey {
        case text, autoCloseDelay, groups
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        text = try container.decode(String.self, forKey: .text)
        autoCloseDelay = try container.decode(Int?.self, forKey: .autoCloseDelay)

        if container.contains(.groups) {
            let groupsDict = try container.decode([String: [String: String]].self, forKey: .groups)
            groups = try groupsDict.map({ (key, value) in
                let messageText = value["message_text"]
                let linkText = value["link_text"]
                let linkURL = value["link_url"]
                if linkText == nil && linkURL != nil {
                    throw GroupPropertyError.missingLinkText
                } else if linkText != nil && linkURL == nil {
                    throw GroupPropertyError.missingLinkURL
                }
                return Group(name: key, messageText: messageText, linkText: linkText, linkURL: linkURL)
            })
        } else {
            groups = []
        }
    }

    public struct Group {
        let name: String
        let messageText: String?
        let linkText: String?
        let linkURL: String?
    }

    enum GroupPropertyError: Error {
        case missingLinkText
        case missingLinkURL
    }
}
