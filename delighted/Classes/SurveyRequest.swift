import Foundation

struct SurveyRequestBody: Encodable {
    let token: String?
    let person: Person?
    let properties: Properties?
    let testMode: Bool

    init(token: String? = nil, person: Person? = nil, properties: Properties? = nil, testMode: Bool? = nil) {
        self.token = token
        self.person = person
        self.properties = properties
        self.testMode = testMode ?? false
    }
}

struct SurveyRequest: Decodable {
    let token: String
    let survey: Survey
    let thankYou: ThankYou
}
