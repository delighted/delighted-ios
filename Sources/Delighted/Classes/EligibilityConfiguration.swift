import Foundation

struct EligibilityConfiguration {
    let surveyContextId: String
    let enabled: Bool
    let minSurveyInterval: Int
    let sampleFactor: Float
    var recurringSurveyPeriod: Int?
    var initialSurveyDelay: Int?
    let forceDisplay: Bool
    let planLimitExhausted: Bool
}

extension EligibilityConfiguration: Decodable {

}

extension EligibilityConfiguration {
    @discardableResult
    mutating func apply(overrides: EligibilityOverrides?) -> EligibilityConfiguration {
        if let initialDelay = overrides?.initialDelay {
            self.initialSurveyDelay = initialDelay
        }
        if let recurringPeriod = overrides?.recurringPeriod {
            self.recurringSurveyPeriod = recurringPeriod
        }

        return self
    }
}

@objc public class EligibilityOverrides: NSObject {
    public let testMode: Bool
    public let createdAt: Date?
    public let initialDelay: Int?
    public let recurringPeriod: Int?

    @objc public init(testMode: Bool = false, createdAt: Date? = nil) {
        self.testMode = testMode
        self.createdAt = createdAt
        self.initialDelay = nil
        self.recurringPeriod = nil
    }

    public init(testMode: Bool = false, createdAt: Date? = nil, initialDelay: Int? = nil, recurringPeriod: Int? = nil) {
        self.testMode = testMode
        self.createdAt = createdAt
        self.initialDelay = initialDelay
        self.recurringPeriod = recurringPeriod
    }
}
