import UIKit

@objc public protocol DelightedDelegate {
    func onStatus(error: Error?, surveyResponseStatus: DelightedSurveyResponseStatus)
}

@objc public enum DelightedSurveyResponseStatus: Int {
    case error, unanswered, saveSuccessful, saveFailed
}

@objc public class Delighted: NSObject {

    /// New window that the survey will be displayed in
    internal static var window: UIWindow?

    internal static var surveying = false

    @objc public static weak var delegate: DelightedDelegate?

    public typealias SurveyCallback = (Status) -> Void

    public enum Status {
        case failedClientEligibility(Error)
        case error(Error)
        case surveyClosed(DelightedSurveyResponseStatus)
    }

    public static var logLevel: Logger {
        get {
            return Logger.level
        }
        set {
            Logger.level = newValue
        }
    }

    @objc public static func initializeSDK() {
        Logger.log(.info, "init")
        RequestCache.retryAll()
    }

    @objc public static func survey(
        delightedID: String,
        token: String? = nil,
        person: Person? = nil,
        properties: Properties? = nil,
        options: Options? = nil,
        eligibilityOverrides: EligibilityOverrides? = nil,
        inViewController userViewController: UIViewController? = nil
    ) {
        survey(
            delightedID:
            delightedID,
            token: token,
            person: person,
            properties: properties,
            options: options,
            eligibilityOverrides: eligibilityOverrides,
            inViewController: userViewController,
            callback: { (status) in
                switch status {
                case .failedClientEligibility(let error):
                    delegate?.onStatus(error: error, surveyResponseStatus: .error)
                case .error(let error):
                    delegate?.onStatus(error: error, surveyResponseStatus: .error)
                case .surveyClosed(let responseStatus):
                    delegate?.onStatus(error: nil, surveyResponseStatus: responseStatus)
                }
        })
    }

    public static func survey(
        delightedID: String,
        token: String? = nil,
        person: Person? = nil,
        properties: Properties? = nil,
        options: Options? = nil,
        eligibilityOverrides: EligibilityOverrides? = nil,
        inViewController userViewController: UIViewController? = nil,
        callback: SurveyCallback? = nil) {

        // Retry sending all failed requests
        RequestCache.retryAll()

        // Only display if another survey is not being displayed
        guard !Delighted.surveying else {
            Logger.log(.warn, "Cannot request survey - another survey window is already open")
            return
        }
        Delighted.surveying = true

        let preSurveySession = PreSurveySession(
            delightedID: delightedID,
            baseURL: options?.baseURL,
            cdnURL: options?.cdnURL,
            callback: callback
        )

        ClientEligibility.init(preSurveySession: preSurveySession).check(with: eligibilityOverrides, whenEligible: {
            Logger.log(.debug, "Passed client side eligibility")
            sendRequestSurvey(
                preSurveySession: preSurveySession,
                token: token,
                person: person,
                properties: properties,
                options: options,
                testMode: eligibilityOverrides?.testMode,
                inViewController: userViewController
            )
        }, whenIneligible: { (failedReason) in
            Logger.log(.debug, "Failed client side eligibility at step \(failedReason)")
            Delighted.surveying = false
            callback?(.failedClientEligibility(failedReason))
        })
    }

    public static func hide(completion: (() -> Void)? = nil) {
        if let root = window?.rootViewController, let delightedPageViewController = root as? DelightedPageViewController {
            delightedPageViewController.surveyViewController.hide {
                window?.rootViewController?.dismiss(animated: false, completion: completion)
            }
        }
    }

    private static func sendRequestSurvey(
        preSurveySession: PreSurveySession,
        token: String? = nil,
        person: Person? = nil,
        properties: Properties? = nil,
        options: Options? = nil,
        testMode: Bool?,
        inViewController userViewController: UIViewController? = nil) {

        // Survey request body
        let surveyRequestBody = SurveyRequestBody(
            token: token,
            person: person,
            properties: properties,
            testMode: testMode
        )

        // Send survey request
        let route = Route.surveyRequest(surveyRequestBody: surveyRequestBody)
        preSurveySession.sendRequest(route: route, completion: { (data, _) in
            DispatchQueue.main.async {
                guard let data = data else {
                    Delighted.surveying = false
                    preSurveySession.callback?(.error(APIError.noResponse))
                    return
                }

                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase

                    let surveyRequest = try decoder.decode(SurveyRequest.self, from: data)

                    var configuration = surveyRequest.survey.configuration
                    configuration.applyOptions(options: options)

                    showSurvey(preSurveySession: preSurveySession, surveyRequest: surveyRequest, configuration: configuration, inViewController: userViewController)
                } catch {
                    Delighted.surveying = false
                    preSurveySession.callback?(.error(APIError.responseDecodeFailure))
                    Logger.log(.error, "Could not decode survey request \(error)")
                }
            }
        }, failure: { (error) in
            DispatchQueue.main.async {
                Delighted.surveying = false
                preSurveySession.callback?(.error(error))
            }
        })
    }

    private static func showSurvey(
        preSurveySession: PreSurveySession,
        surveyRequest: SurveyRequest,
        configuration: SurveyConfiguration,
        inViewController userViewController: UIViewController? = nil
        ) {

        // Finds window and root view controller for presenting
        // TOOD: look into iOS 13 weirdness
        guard (userViewController ?? UIApplication.shared.keyWindow?.rootViewController) != nil else {
            Logger.log(.fatal, "No window or root view controller to present on")
            return
        }

        let surveyResponse = SurveyResponse(
            delightedID: preSurveySession.delightedID,
            surveyRequestToken: surveyRequest.token
        )

        let session = SurveySession(
            preSurveySession: preSurveySession,
            surveyRequest: surveyRequest,
            surveyResponse: surveyResponse,
            configuration: configuration
        )
        session.connectPusher()

        let window: UIWindow = {
            // Need to check if UIScene in iOS 13 and higher
            // If yes, then create a window with the scene
            // Else, create a window with the screen bounds
            if #available(iOS 13.0, *) {
                let windowScene = UIApplication.shared
                    .connectedScenes
                    .filter { $0.activationState == .foregroundActive }
                    .first

                if let windowScene = windowScene as? UIWindowScene {
                    return UIWindow(windowScene: windowScene)
                }
            }

            return UIWindow(frame: UIScreen.main.bounds)
        }()

        // Making a new window for navigation controller
        // This is needed so that Delighted can force portrait
        window.windowLevel = .normal
        window.isHidden = false
        window.makeKeyAndVisible()
        window.backgroundColor = Colors.clear

        Delighted.window = window

        // Sets up transparent navigation controller to lay over current context
        let navigationController = DelightedPageViewController(session: session)

        navigationController.view.backgroundColor = Colors.clear
        navigationController.modalPresentationStyle = .overCurrentContext
        navigationController.modalTransitionStyle = .coverVertical

        window.rootViewController = navigationController
    }
}

public enum Logger: Int {
    case off, fatal, error, warn, info, debug

    static var level = Logger.error

    var label: String {
        switch self {
        case .off:
            return "OFF"
        case .fatal:
            return "FATAL"
        case .error:
            return "ERROR"
        case .warn:
            return "WARN"
        case .info:
            return "INFO"
        case .debug:
            return "DEBUG"
        }
    }

    static func log(_ logger: Logger, _ message: String) {
        guard logger != .off && logger.rawValue <= Logger.level.rawValue else { return }
        print("Delighted::\(logger.label) - \(message)")
    }
}
