import Foundation

// Public only for testing
public struct Survey: Decodable {
    let type: SurveyType
    let configuration: SurveyConfiguration
    let template: Template

    public struct SurveyType: Decodable {
        let id: ID
        let groups: [Group]

        enum CodingKeys: CodingKey {
            case id, groups, configuration
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(ID.self, forKey: .id)

            let groupsDict = try container.decode([String: [String: Int]].self, forKey: .groups)
            groups = try groupsDict.map({ (key, value) in
                guard let scoreMin = value["score_min"], let scoreMax = value["score_max"] else {
                    // TODO: Is this the right thing todo?
                    throw GroupPropertyError()
                }
                return Group(name: key, scoreMin: scoreMin, scoreMax: scoreMax)
            })
        }

        public enum ID: String, Decodable {
            case csat, csat3, ces, ces7, smileys, starsFive = "stars_five", thumbs, nps, enps, pmf
        }

        public struct Group {
            let name: String
            let scoreMin: Int
            let scoreMax: Int
        }

        // TODO: Is this the right thing todo?
        struct GroupPropertyError: Error {
        }
    }

    public struct Template: Decodable {
        let questionText: String
        let scoreText: [String: String]?
        let commentPrompts: [String: String]
        let additionalQuestions: [AdditionalQuestion]

        enum CodingKeys: CodingKey {
            case questionText, scoreText, commentPrompts, additionalQuestions
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            questionText = try container.decode(String.self, forKey: .questionText)

            if container.contains(.scoreText) {
                scoreText = try container.decode([String: String].self, forKey: .scoreText)
            } else {
                scoreText = [:]
            }

            commentPrompts = try container.decode([String: String].self, forKey: .commentPrompts)

            if container.contains(.additionalQuestions) {
                additionalQuestions = try container.decode([AdditionalQuestion].self, forKey: .additionalQuestions)
            } else {
                additionalQuestions = []
            }
        }

        public struct AdditionalQuestion: Decodable {
            let id: String
            let type: AdditionalQuestionType
            let text: String

            let options: [Option]?
            let scaleMin: Int?
            let scaleMax: Int?
            let scaleMinLabel: String?
            let scaleMaxLabel: String?

            let targetAudienceGroups: [String]?

            public enum AdditionalQuestionType: String, Decodable {
                case selectOne = "select_one", selectMany = "select_many", scale, freeResponse = "free_response"
            }

            public struct Option: Decodable {
                let id: String
                let text: String
            }
        }
    }
}
