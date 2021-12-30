import Foundation
import UIKit

internal struct ClientEligibility {
    typealias EligibilityCheckPassed = () -> Void
    typealias EligibilityCheckFailure = (FailedReason) -> Void

    internal enum FailedReason: Error {
        case cannotGetConfiguration, enabled, exhausted, initialDelay, recurringPeriod, recurringLessThanMinimum, randomSampleFactor(Double), unsupportedDevice, recurringSurveyDisabled
    }

    let preSurveySession: PreSurveySession
    init(preSurveySession: PreSurveySession) {
        self.preSurveySession = preSurveySession
    }
}

extension ClientEligibility {
    // Pull last surveyed from UserDefaults specific to this Delighted token/project
    func getDefaults(with eligibilityConfiguration: EligibilityConfiguration) -> UserDefaults? {
        return UserDefaults(suiteName: "Delighted-\(eligibilityConfiguration.surveyContextId)")
    }

    func firstSeenDate(defaults: UserDefaults?) -> Date {
        let date = defaults?.object(forKey: "firstSeen") as? Date ?? Date()
        defaults?.set(date, forKey: "firstSeen")
        return date
    }

    func setFirstSeenDate(defaults: UserDefaults?, date: Date?) {
        defaults?.set(date, forKey: "firstSeen")
    }

    func lastSurveyedDate(defaults: UserDefaults?) -> Date? {
        return defaults?.object(forKey: "lastSurveyed") as? Date
    }

    func setLastSurveyedDate(defaults: UserDefaults?, date: Date?) {
        defaults?.set(date, forKey: "lastSurveyed")
    }
}

extension ClientEligibility {
    func check(
        with overrides: EligibilityOverrides? = nil,
        whenEligible passed: @escaping EligibilityCheckPassed,
        whenIneligible failure:  @escaping EligibilityCheckFailure) {

        if !isDeviceSupported() {
            failure(.unsupportedDevice)
            return
        }

        // Pass right away if developer is testing
        if let isTest = overrides?.testMode, isTest {
            passed()
            return
        }

        // Fetch eligibility configuration
        let route = Route.eligibilityConfiguration
        preSurveySession.sendRequest(route: route, completion: { (data, _) in
            DispatchQueue.main.async {
                guard let data = data else {
                    failure(.cannotGetConfiguration)
                    return
                }

                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase

                    // Apply developer overrides on top of configuration from API
                    var eligibilityConfiguration = try decoder.decode(EligibilityConfiguration.self, from: data)
                    eligibilityConfiguration.apply(overrides: overrides)

                    // Perform client side eligibility checks now
                    self.doClientSideCheck(overrides: overrides, eligibilityConfiguration: eligibilityConfiguration, passed: { () in
                        // Set last surveyed and then continue on with the passing
                        let defaults = self.getDefaults(with: eligibilityConfiguration)
                        self.setLastSurveyedDate(defaults: defaults, date: Date())

                        passed()
                    }, failure: failure)
                } catch {
                    failure(.cannotGetConfiguration)
                    Logger.log(.error, "Could not decode eligibility configuration request")
                }
            }
        }, failure: { (error) in
            DispatchQueue.main.async {
                Logger.log(.error, "Could not complete eligibility configuration request \(error.localizedDescription)")
                failure(.cannotGetConfiguration)
            }
        })
    }
}

internal extension ClientEligibility {
    static let iPhoneMinHeight: CGFloat = 667.0 // iPhone 6 and newer screen sizes

    func isDeviceSupported() -> Bool {
        return UIDevice.current.userInterfaceIdiom == .phone && UIScreen.main.bounds.height >= ClientEligibility.iPhoneMinHeight
    }

    func doClientSideCheck(overrides: EligibilityOverrides? = nil, eligibilityConfiguration: EligibilityConfiguration, passed: @escaping EligibilityCheckPassed, failure: @escaping EligibilityCheckFailure) {

        // Fail if not enabled
        if !eligibilityConfiguration.enabled {
            failure(.enabled)
            return
        }

        // Fail if plan exhausted
        if eligibilityConfiguration.planLimitExhausted {
            failure(.exhausted)
            return
        }

        // Skip checking if force display
        if !eligibilityConfiguration.forceDisplay {

            // Getting defaults object to get cached data
            let defaults = self.getDefaults(with: eligibilityConfiguration)

            // Skip checking if no created at or last surveyed
            if let lastSurveyed = self.lastSurveyedDate(defaults: defaults) {
                // Fail when a person has been surveyed but recurring surveys aren't enabled
                if eligibilityConfiguration.recurringSurveyPeriod == nil {
                    failure(.recurringSurveyDisabled)
                    return
                }

                // Fail if less than recurring time
                let recurring = TimeInterval(eligibilityConfiguration.recurringSurveyPeriod!)
                if lastSurveyed.addingTimeInterval(recurring) >= Date() {
                    failure(.recurringPeriod)
                    return
                }

                // Fail if recurring period less than minimum survey interval
                // Note: this will only ever fail if developer override caused this to happen
                if eligibilityConfiguration.recurringSurveyPeriod! < eligibilityConfiguration.minSurveyInterval {
                    failure(.recurringLessThanMinimum)
                    return
                }
            } else if let initialSurveyDelay = eligibilityConfiguration.initialSurveyDelay {
                let createdAtOrLastSurveyedAt = overrides?.createdAt ?? firstSeenDate(defaults: defaults)

                // Fail if last surveyed is less than initial delay.
                let delay = TimeInterval(initialSurveyDelay)
                if createdAtOrLastSurveyedAt.addingTimeInterval(delay) >= Date() {
                    failure(.initialDelay)
                    return
                }
            }
        }

        self.doRandomSampleFactor(sampleFactor: eligibilityConfiguration.sampleFactor, passed: passed, failure: failure)
    }

    func doRandomSampleFactor(sampleFactor: Float, passed: EligibilityCheckPassed, failure: @escaping EligibilityCheckFailure) {

        // Pass if random number is less than the sample factor
        let random = drand48()
        if random <= Double(sampleFactor) {
            Logger.log(.debug, "Eligibility passed because \(random) <= \(sampleFactor)")
            passed()
        } else {
            Logger.log(.debug, "Eligibility failed because \(random) > \(sampleFactor)")
            failure(.randomSampleFactor(random))
        }
    }
}
