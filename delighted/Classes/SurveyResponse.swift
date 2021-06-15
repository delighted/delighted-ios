import Foundation

struct SurveyResponse: Encodable {
    let delightedID: String

    let surveyRequestToken: String
    var score: Int?
    var comment: String?

    private var additionalQuestions: [AdditionalQuestionAnswer]

    enum CodingKeys: String, CodingKey {
        case surveyRequestToken, score, comment, additionalQuestions
    }

    init(delightedID: String, surveyRequestToken: String, score: Int? = nil) {
        self.delightedID = delightedID
        self.surveyRequestToken = surveyRequestToken
        self.score = score
        self.additionalQuestions = []
    }

    struct AdditionalQuestionAnswer: Codable {
        let id: String
        let value: String
    }

    mutating func addAnswer(id: String, value: String) {
        additionalQuestions.removeAll { (answer) -> Bool in
            return answer.id == id
        }

        let answer = AdditionalQuestionAnswer(id: id, value: value)
        additionalQuestions.append(answer)
    }
}
