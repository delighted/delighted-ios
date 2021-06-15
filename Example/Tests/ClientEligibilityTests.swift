import XCTest
@testable import Delighted

class ClientEligibilityTests: XCTestCase {

    var preSurveySession = PreSurveySession(delightedID: "", baseURL: nil, cdnURL: nil, callback: nil)

    var configuration = EligibilityConfiguration(
        surveyContextId: "",
        enabled: false,
        minSurveyInterval: 0,
        sampleFactor: 1,
        recurringSurveyPeriod: 1,
        initialSurveyDelay: 1,
        forceDisplay: false,
        planLimitExhausted: false
    )

    func testOverrides() {
        XCTAssertEqual(configuration.enabled, false)
        XCTAssertEqual(configuration.minSurveyInterval, 0)
        XCTAssertEqual(configuration.sampleFactor, 1)
        XCTAssertEqual(configuration.recurringSurveyPeriod, 1)
        XCTAssertEqual(configuration.initialSurveyDelay, 1)
        XCTAssertEqual(configuration.forceDisplay, false)
        XCTAssertEqual(configuration.planLimitExhausted, false)

        let overrides = EligibilityOverrides(
            testMode: false,
            createdAt: nil,
            initialDelay: 100,
            recurringPeriod: 200
        )
        configuration.apply(overrides: overrides)

        XCTAssertEqual(configuration.enabled, false)
        XCTAssertEqual(configuration.minSurveyInterval, 0)
        XCTAssertEqual(configuration.sampleFactor, 1)
        XCTAssertEqual(configuration.recurringSurveyPeriod, 200)
        XCTAssertEqual(configuration.initialSurveyDelay, 100)
        XCTAssertEqual(configuration.forceDisplay, false)
        XCTAssertEqual(configuration.planLimitExhausted, false)
    }

    func testPassOnTest() {
        let passExpectation = expectation(description: "Pass")

        let overrides = EligibilityOverrides(testMode: true)
        let eligibility = ClientEligibility(preSurveySession: preSurveySession)

        let defaults = eligibility.getDefaults(with: configuration)
        eligibility.setFirstSeenDate(defaults: defaults, date: nil)

        eligibility.check(with: overrides, whenEligible: {

            passExpectation.fulfill()
        }) { (_) in
            XCTFail("Check should have passed right away")
        }

        waitForExpectations(timeout: 0.3, handler: nil)
    }

    func testFailOnEnabledFalse() {
        let eligibility = ClientEligibility(preSurveySession: preSurveySession)
        let defaults = eligibility.getDefaults(with: configuration)
        eligibility.setFirstSeenDate(defaults: defaults, date: nil)

        let configuration = EligibilityConfiguration(
            surveyContextId: "",
            enabled: false,
            minSurveyInterval: 0,
            sampleFactor: 1,
            recurringSurveyPeriod: 1,
            initialSurveyDelay: 1,
            forceDisplay: false,
            planLimitExhausted: false
        )

        let failExpectation = expectation(description: "Fail")
        eligibility.doClientSideCheck(eligibilityConfiguration: configuration, passed: {

        }) { (failedReason) in
            if case ClientEligibility.FailedReason.enabled = failedReason {
                // Success
            } else {
                XCTFail("wrong error")
            }
            failExpectation.fulfill()
        }

        waitForExpectations(timeout: 0.3, handler: nil)
    }

    func testFailOnPlanExhaustedTrue() {
        let eligibility = ClientEligibility(preSurveySession: preSurveySession)
        let defaults = eligibility.getDefaults(with: configuration)
        eligibility.setFirstSeenDate(defaults: defaults, date: nil)

        let configuration = EligibilityConfiguration(
            surveyContextId: "",
            enabled: true,
            minSurveyInterval: 0,
            sampleFactor: 1,
            recurringSurveyPeriod: 1,
            initialSurveyDelay: 1,
            forceDisplay: false,
            planLimitExhausted: true
        )

        let failExpectation = expectation(description: "Fail")
        eligibility.doClientSideCheck(eligibilityConfiguration: configuration, passed: {

        }) { (failedReason) in
            if case ClientEligibility.FailedReason.exhausted = failedReason {
                // Success
            } else {
                XCTFail("wrong error")
            }
            failExpectation.fulfill()
        }

        waitForExpectations(timeout: 0.3, handler: nil)
    }

    func testPassOnForceDisplayTrue() {
        let eligibility = ClientEligibility(preSurveySession: preSurveySession)
        let defaults = eligibility.getDefaults(with: configuration)
        eligibility.setFirstSeenDate(defaults: defaults, date: nil)

        let configuration = EligibilityConfiguration(
            surveyContextId: "",
            enabled: true,
            minSurveyInterval: 0,
            sampleFactor: 1,
            recurringSurveyPeriod: 1,
            initialSurveyDelay: 1,
            forceDisplay: true,
            planLimitExhausted: false
        )

        let passExpectation = expectation(description: "Pass")
        eligibility.doClientSideCheck(eligibilityConfiguration: configuration, passed: {
            passExpectation.fulfill()
        }) { (_) in

        }

        waitForExpectations(timeout: 0.3, handler: nil)
    }

    func testPassOnNotPreviousSurveyedWithNoInitialDelay() {
        let eligibility = ClientEligibility(preSurveySession: preSurveySession)
        let defaults = eligibility.getDefaults(with: configuration)
        eligibility.setFirstSeenDate(defaults: defaults, date: nil)
        eligibility.setLastSurveyedDate(defaults: defaults, date: nil)

        let configuration = EligibilityConfiguration(
            surveyContextId: "",
            enabled: true,
            minSurveyInterval: 0,
            sampleFactor: 1,
            recurringSurveyPeriod: 1,
            initialSurveyDelay: 0,
            forceDisplay: false,
            planLimitExhausted: false
        )

        let passExpectation = expectation(description: "Pass")
        eligibility.doClientSideCheck(eligibilityConfiguration: configuration, passed: {
            passExpectation.fulfill()
        }) { (_) in

        }

        waitForExpectations(timeout: 0.3, handler: nil)
    }

    func testFailOnNotPreviousSurveyedWithInitialDelay() {
        let eligibility = ClientEligibility(preSurveySession: preSurveySession)
        let defaults = eligibility.getDefaults(with: configuration)
        eligibility.setFirstSeenDate(defaults: defaults, date: nil)
        eligibility.setLastSurveyedDate(defaults: defaults, date: nil)

        let configuration = EligibilityConfiguration(
            surveyContextId: "",
            enabled: true,
            minSurveyInterval: 0,
            sampleFactor: 1,
            recurringSurveyPeriod: 1,
            initialSurveyDelay: 60,
            forceDisplay: false,
            planLimitExhausted: false
        )

        let failExpectation = expectation(description: "Fail")
        eligibility.doClientSideCheck(eligibilityConfiguration: configuration, passed: {

        }) { (failedReason) in
            if case ClientEligibility.FailedReason.initialDelay = failedReason {
                // Success
            } else {
                XCTFail("wrong error")
            }
            failExpectation.fulfill()
        }

        waitForExpectations(timeout: 0.3, handler: nil)
    }

    func testFailOnNotPreviousSurveyedButOverriddenCreatedAt() {
        let eligibility = ClientEligibility(preSurveySession: preSurveySession)
        let defaults = eligibility.getDefaults(with: configuration)
        eligibility.setFirstSeenDate(defaults: defaults, date: nil)
        eligibility.setLastSurveyedDate(defaults: defaults, date: nil)

        var configuration = EligibilityConfiguration(
            surveyContextId: "",
            enabled: true,
            minSurveyInterval: 0,
            sampleFactor: 1,
            recurringSurveyPeriod: 1,
            initialSurveyDelay: 60,
            forceDisplay: false,
            planLimitExhausted: false
        )

        let createdAt = Date().addingTimeInterval(-59)
        let overrides = EligibilityOverrides(createdAt: createdAt)
        configuration.apply(overrides: overrides)

        let failExpectation = expectation(description: "Fail")
        eligibility.doClientSideCheck(overrides: overrides, eligibilityConfiguration: configuration, passed: {

        }) { (failedReason) in
            if case ClientEligibility.FailedReason.initialDelay = failedReason {
                // Success
            } else {
                XCTFail("wrong error")
            }
            failExpectation.fulfill()
        }

        waitForExpectations(timeout: 0.3, handler: nil)
    }

    func testFailOnNotPreviousSurveyedButInitialDelayInFuture() {
        let eligibility = ClientEligibility(preSurveySession: preSurveySession)
        let defaults = eligibility.getDefaults(with: configuration)
        eligibility.setFirstSeenDate(defaults: defaults, date: nil)
        eligibility.setLastSurveyedDate(defaults: defaults, date: nil)

        let configuration = EligibilityConfiguration(
            surveyContextId: "",
            enabled: true,
            minSurveyInterval: 0,
            sampleFactor: 1,
            recurringSurveyPeriod: 1,
            initialSurveyDelay: 60,
            forceDisplay: false,
            planLimitExhausted: false
        )

        let failExpectation = expectation(description: "Fail")
        eligibility.doClientSideCheck(eligibilityConfiguration: configuration, passed: {

        }) { (failedReason) in
            if case ClientEligibility.FailedReason.initialDelay = failedReason {
                // Success
            } else {
                XCTFail("wrong error")
            }
            failExpectation.fulfill()
        }

        waitForExpectations(timeout: 0.3, handler: nil)
    }

    func testPassOnNotPreviousSurveyedButInitialDelayInPast() {
        let dateAnHourAgo = Date().addingTimeInterval(-61)

        let eligibility = ClientEligibility(preSurveySession: preSurveySession)
        let defaults = eligibility.getDefaults(with: configuration)
        eligibility.setFirstSeenDate(defaults: defaults, date: dateAnHourAgo)
        eligibility.setLastSurveyedDate(defaults: defaults, date: dateAnHourAgo)

        let configuration = EligibilityConfiguration(
            surveyContextId: "",
            enabled: true,
            minSurveyInterval: 0,
            sampleFactor: 1,
            recurringSurveyPeriod: 1,
            initialSurveyDelay: 60,
            forceDisplay: false,
            planLimitExhausted: false
        )

        let passExpectation = expectation(description: "Pass")
        eligibility.doClientSideCheck(eligibilityConfiguration: configuration, passed: {
            passExpectation.fulfill()
        }) { (_) in

        }

        waitForExpectations(timeout: 0.3, handler: nil)
    }

    func testFailOnUnderRecurringTime() {
        let dateAnHourAgo = Date().addingTimeInterval(-59)

        let eligibility = ClientEligibility(preSurveySession: preSurveySession)
        let defaults = eligibility.getDefaults(with: configuration)
        eligibility.setFirstSeenDate(defaults: defaults, date: dateAnHourAgo)
        eligibility.setLastSurveyedDate(defaults: defaults, date: dateAnHourAgo)

        let configuration = EligibilityConfiguration(
            surveyContextId: "",
            enabled: true,
            minSurveyInterval: 0,
            sampleFactor: 1,
            recurringSurveyPeriod: 60,
            initialSurveyDelay: 0,
            forceDisplay: false,
            planLimitExhausted: false
        )

        let failExpectation = expectation(description: "Fail")
        eligibility.doClientSideCheck(eligibilityConfiguration: configuration, passed: {

        }) { (failedReason) in
            if case ClientEligibility.FailedReason.recurringPeriod = failedReason {
                // Success
            } else {
                XCTFail("wrong error")
            }
            failExpectation.fulfill()
        }

        waitForExpectations(timeout: 0.3, handler: nil)
    }

    func testPassOnRecurring() {
        let dateAnHourAgo = Date().addingTimeInterval(-61)

        let eligibility = ClientEligibility(preSurveySession: preSurveySession)
        let defaults = eligibility.getDefaults(with: configuration)
        eligibility.setFirstSeenDate(defaults: defaults, date: dateAnHourAgo)
        eligibility.setLastSurveyedDate(defaults: defaults, date: dateAnHourAgo)

        let configuration = EligibilityConfiguration(
            surveyContextId: "",
            enabled: true,
            minSurveyInterval: 60,
            sampleFactor: 1,
            recurringSurveyPeriod: 60,
            initialSurveyDelay: 0,
            forceDisplay: false,
            planLimitExhausted: false
        )

        let passExpectation = expectation(description: "Pass")
        eligibility.doClientSideCheck(eligibilityConfiguration: configuration, passed: {
            passExpectation.fulfill()
        }) { (_) in

        }

        waitForExpectations(timeout: 0.3, handler: nil)
    }

    func testFailOnRecurringTimeLessThanMinimum() {
        let dateAnHourAgo = Date().addingTimeInterval(-61)

        let eligibility = ClientEligibility(preSurveySession: preSurveySession)
        let defaults = eligibility.getDefaults(with: configuration)
        eligibility.setFirstSeenDate(defaults: defaults, date: dateAnHourAgo)
        eligibility.setLastSurveyedDate(defaults: defaults, date: dateAnHourAgo)

        let configuration = EligibilityConfiguration(
            surveyContextId: "",
            enabled: true,
            minSurveyInterval: 61,
            sampleFactor: 1,
            recurringSurveyPeriod: 60,
            initialSurveyDelay: 0,
            forceDisplay: false,
            planLimitExhausted: false
        )

        let failExpectation = expectation(description: "Fail")
        eligibility.doClientSideCheck(eligibilityConfiguration: configuration, passed: {

        }) { (failedReason) in
            if case ClientEligibility.FailedReason.recurringLessThanMinimum = failedReason {
                // Success
            } else {
                XCTFail("wrong error")
            }
            failExpectation.fulfill()
        }

        waitForExpectations(timeout: 0.3, handler: nil)
    }

    func testFailOnSampleFactor() {
        let dateAnHourAgo = Date().addingTimeInterval(-61)

        let eligibility = ClientEligibility(preSurveySession: preSurveySession)
        let defaults = eligibility.getDefaults(with: configuration)
        eligibility.setFirstSeenDate(defaults: defaults, date: dateAnHourAgo)
        eligibility.setLastSurveyedDate(defaults: defaults, date: dateAnHourAgo)

        let configuration = EligibilityConfiguration(
            surveyContextId: "",
            enabled: true,
            minSurveyInterval: 60,
            sampleFactor: 0,
            recurringSurveyPeriod: 60,
            initialSurveyDelay: 0,
            forceDisplay: false,
            planLimitExhausted: false
        )

        let failExpectation = expectation(description: "Fail")
        eligibility.doClientSideCheck(eligibilityConfiguration: configuration, passed: {

        }) { (_) in
            failExpectation.fulfill()
        }

        waitForExpectations(timeout: 0.3, handler: nil)
    }

    func testFailWithRecurringSurveyDisabled() {
        // Set up a person that was previously surveyed
        let dateAnHourAgo = Date().addingTimeInterval(-61)
        let eligibility = ClientEligibility(preSurveySession: preSurveySession)
        let defaults = eligibility.getDefaults(with: configuration)
        eligibility.setFirstSeenDate(defaults: defaults, date: dateAnHourAgo)
        eligibility.setLastSurveyedDate(defaults: defaults, date: dateAnHourAgo)

        let configuration = EligibilityConfiguration(
            surveyContextId: "",
            enabled: true,
            minSurveyInterval: 60,
            sampleFactor: 1,
            recurringSurveyPeriod: nil,
            initialSurveyDelay: 0,
            forceDisplay: false,
            planLimitExhausted: false
        )

        let failExpectation = expectation(description: "Fail")
        eligibility.doClientSideCheck(eligibilityConfiguration: configuration, passed: {

        }) { (failedReason) in
            if case ClientEligibility.FailedReason.recurringSurveyDisabled = failedReason {
                // Success
            } else {
                XCTFail("wrong error")
            }
            failExpectation.fulfill()
        }

        waitForExpectations(timeout: 0.3, handler: nil)
    }
}
