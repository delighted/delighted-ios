import Foundation

private let productionBaseURL = URL(string: "https://mobile-sdk-api.delighted.com/v1")!
private let productionCDNURL = URL(string: "https://d2xjuvt32ceggq.cloudfront.net/v1")!

/**
 Used to create and send API requests which need a base url and a delighted ID
 */
protocol Session {
    var delightedID: String { get }
    var baseURL: URL? { get }
    var cdnURL: URL? { get }
    var callback: Delighted.SurveyCallback? { get }
}

extension Session {
    var requestBaseURL: URL {
        return (baseURL ?? productionBaseURL).appendingPathComponent(delightedID)
    }

    var requestCDNURL: URL {
        return (cdnURL ?? productionCDNURL).appendingPathComponent(delightedID)
    }

    func sendRequest(route: Route, completion: @escaping (Data?, HTTPURLResponse?) -> Void, failure: @escaping (Error) -> Void) {
        do {
            let request = try Request(baseURL: (route.useCDN ? requestCDNURL : requestBaseURL), route: route)
            request.send(completion: completion, failure: failure)
        } catch {
            failure(error)
        }
    }
}

/**
 Conforms to Session and only contains information needed before a survey is taken
 */
class PreSurveySession: Session {
    let delightedID: String
    let baseURL: URL?
    let cdnURL: URL?
    let callback: Delighted.SurveyCallback?

    init(delightedID: String, baseURL: URL?, cdnURL: URL?, callback: Delighted.SurveyCallback?) {
        self.delightedID = delightedID
        self.baseURL = baseURL
        self.cdnURL = cdnURL
        self.callback = callback
    }
}

/**
 Confroms to Session and contains all info needed to display surveys and send survey responses
 */
class SurveySession: Session {
    let delightedID: String
    let baseURL: URL?
    let cdnURL: URL?
    let callback: Delighted.SurveyCallback?

    let surveyRequest: SurveyRequest
    var surveyResponse: SurveyResponse
    let configuration: SurveyConfiguration
    var status = DelightedSurveyResponseStatus.unanswered

    var pusher: Pusher?

    init(preSurveySession: PreSurveySession, surveyRequest: SurveyRequest, surveyResponse: SurveyResponse, configuration: SurveyConfiguration) {
        self.delightedID = preSurveySession.delightedID
        self.baseURL = preSurveySession.baseURL
        self.cdnURL = preSurveySession.cdnURL
        self.callback = preSurveySession.callback
        self.surveyRequest = surveyRequest
        self.surveyResponse = surveyResponse
        self.configuration = configuration
    }

    func connectPusher() {
        guard surveyRequest.survey.configuration.pusher.enabled else {
            Logger.log(.info, "Pusher is disabled")
            return
        }

        guard let url = URL(string: surveyRequest.survey.configuration.pusher.webSocketUrl!) else {
            Logger.log(.error, "Pusher websocket url is invalid")
            return
        }

        pusher = Pusher(
            websocketURL: url,
            baseAPIURL: requestBaseURL,
            channelName: surveyRequest.survey.configuration.pusher.channelName!,
            surveyRequestToken: surveyRequest.token
        )
        pusher?.connect()
    }

    func disconnectPusher() {
        pusher?.disconnect()
    }

    func sendClientTyping() {
        pusher?.sendClientTyping()
    }
}

extension SurveySession {
    func saveSurveyResponse() {
        let route = Route.surveyResponse(surveyResponse: surveyResponse)
        sendRequest(route: route, completion: { [unowned self] (_, _) in
            self.status = .saveSuccessful
            Logger.log(.debug, "Survey response saved for Survey Request Token: \(self.surveyResponse.surveyRequestToken)")
        }, failure: { [unowned self] (error) in
            self.status = .saveFailed
            Logger.log(.debug, "Survey response failed Survey Request Token: \(self.surveyResponse.surveyRequestToken) with \(error.localizedDescription)")
        })
    }
}
