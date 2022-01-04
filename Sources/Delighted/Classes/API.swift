import UIKit

/**
 Enumeration of all the possible API routes which contains:
 - path: String - The path that gets appended to the base url
 - method: String - GET, POST, PUT, DELETE, PATCH, OPTIONS
 - accepts: String? - Optional accepts header
 - contentType: String? - Optional content type header
 - offlineSaveID: String? - Optional ID that is used to save for offline cache
 */
enum Route {
    case surveyRequest(surveyRequestBody: SurveyRequestBody)
    case surveyResponse(surveyResponse: SurveyResponse)
    case eligibilityConfiguration
    case pusherAuth(pusherAuthRequest: PusherAuthRequest)

    var useCDN: Bool {
        switch self {
        case .eligibilityConfiguration: return true
        default: return false
        }
    }

    var path: String {
        switch self {
        case .surveyRequest: return "/survey_requests"
        case .surveyResponse: return "/survey_responses"
        case .eligibilityConfiguration: return "/configuration"
        case .pusherAuth: return "/pusher/auth"
        }
    }

    var method: String {
        switch self {
        case .surveyRequest: return "POST"
        case .surveyResponse: return "POST"
        case .eligibilityConfiguration: return "GET"
        case .pusherAuth: return "POST"
        }
    }

    var accept: String? {
        switch self {
        case .surveyRequest, .surveyResponse, .eligibilityConfiguration, .pusherAuth:
            return "application/json"
        }
    }

    var contentType: String? {
        switch self {
        case .surveyRequest, .surveyResponse, .pusherAuth:
            return "application/json"
        case .eligibilityConfiguration:
            return nil
        }
    }

    var offlineSaveID: String? {
        switch self {
        case let .surveyResponse(surveyResponse):
            return surveyResponse.surveyRequestToken
        case .surveyRequest, .eligibilityConfiguration, .pusherAuth:
            return nil
        }
    }

    func makeBody() throws -> Data? {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase

        switch self {
        case let .surveyRequest(surveyRequestBody):
            return try encoder.encode(surveyRequestBody)
        case let .surveyResponse(surveyResponse):
            return try encoder.encode(surveyResponse)
        case .eligibilityConfiguration:
            return nil
        case let .pusherAuth(pusherAuthRequest):
            return try encoder.encode(pusherAuthRequest)
        }
    }
}

enum APIError: Error {
    case invalidURL, invalidRequestBody, noResponse, badRequest(Int, Data, HTTPURLResponse), responseDecodeFailure
}

/**
 Used to generate and send a URLRequest.
 
 It conforms to Codable so that it can be encoded and decoded from file for
 offline caching. This class wouldn't be necessary if URLRequest itself
 conformed to Codable
 */
struct Request: Codable {
    let url: URL
    let method: String
    let accept: String?
    let contentType: String?
    let body: Data?

    let offlineSaveID: String?
    var retryCount: Int = 5

    var userAgent: String {
        return "DelightedSDK/\(VERSION) (iPhone; iOS \(UIDevice.current.systemVersion))"
    }

    static var session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config)
    }()

    init(baseURL: URL, route: Route) throws {
        let url = baseURL.appendingPathComponent(route.path)

        self.url = url
        self.method = route.method
        self.accept = route.accept
        self.contentType = route.contentType
        self.body = try route.makeBody()
        self.offlineSaveID = route.offlineSaveID
    }

    private func makeURLRequest() throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue(userAgent, forHTTPHeaderField: "User-Agent")

        if let accept = accept {
            request.addValue(accept, forHTTPHeaderField: "Accept")
        }
        if let contentType = contentType {
            request.addValue(contentType, forHTTPHeaderField: "Content-Type")
        }

        request.httpBody = body

        return request
    }
}

extension Request {
    /**
     Takes this request and attempts to send to the API
     1. Attemps to make a URLRequest
     2. Sends the URLRequest
     3. Fails if no response and stores offline to retry later if offlineSaveID exists
     4. Fails if not 2XX and stores offline to retry later if offlineSaveID exists
     5. Attempts removes from offline cache (since this may have been a retry
     6. Completion block called
     */
    func send(completion: @escaping (Data?, HTTPURLResponse?) -> Void, failure: @escaping (Error) -> Void) {
        do {
            let urlRequest = try makeURLRequest()

            Logger.log(.debug, "\(urlRequest.httpMethod ?? "") \(urlRequest.url?.absoluteString ?? "")")
            if let data = urlRequest.httpBody, let body = String(bytes: data, encoding: .utf8) {
                Logger.log(.debug, "\t\(body)")
            }

            // make the request
            let task = Request.session.dataTask(with: urlRequest) { (data, response, _) in
                // Verify a data and a response
                guard let data = data, let response = response as? HTTPURLResponse else {
                    RequestCache.store(request: self)
                    failure(APIError.noResponse)
                    return
                }

                let requestID = response.allHeaderFields["X-Request-Id"] ?? ""
                Logger.log(.debug, "\(requestID) \(urlRequest.httpMethod ?? "") \(urlRequest.url?.absoluteString ?? "") - \(response.statusCode)")

                // Verify a 2XX
                guard 200...299 ~= response.statusCode else {
                    RequestCache.store(request: self)
                    failure(APIError.badRequest(response.statusCode, data, response))
                    return
                }

                RequestCache.remove(request: self)
                completion(data, response)
            }
            task.resume()
        } catch {
            Logger.log(.error, "Could not create URL request \(error.localizedDescription)")
            failure(error)
        }
    }
}

/**
 Handles all operations for reading, writing, and removing Request objects from documents cache directory
 */
struct RequestCache {
    static let fileExtension = "json"

    static var directoryURL: URL? = {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent("delighted")
    }()

    /**
     Finds all files and decodes them into Request objects
     */
    static func all() -> [Request] {
        guard let directoryURL = RequestCache.directoryURL else {
            return []
        }

        // Get list of file paths for requests saved that need resending
        let urls = try? FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)

        // Maps file paths to decoded request objects
        return urls?.compactMap { (url) -> Request? in
            if !FileManager.default.fileExists(atPath: url.path) {
                return nil
            }

            if let data = FileManager.default.contents(atPath: url.path) {
                let decoder = JSONDecoder()
                let model = try? decoder.decode(Request.self, from: data)
                return model
            }

            return nil
        } ?? []

    }

    /**
     Writes the Request to disk (if offlineSaveID exists)
     */
    static func store(request: Request) {
        guard let directoryURL = RequestCache.directoryURL, let filename = request.offlineSaveID else {
            return
        }

        let fileURL = directoryURL
            .appendingPathComponent(filename)
            .appendingPathExtension(fileExtension)

        // Create cache directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: directoryURL.absoluteString) {
            try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        }

        // Attempt to encode the request to save for sending later
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(request)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }
            FileManager.default.createFile(atPath: fileURL.path, contents: data, attributes: nil)
        } catch {
            Logger.log(.error, error.localizedDescription)
        }
    }

    /**
     Attempts to remove the Request (if offlineSaveID exists) from disk
     */
    static func remove(request: Request) {
        guard let directoryURL = RequestCache.directoryURL, let filename = request.offlineSaveID else {
            return
        }

        let fileURL = directoryURL
            .appendingPathComponent(filename)
            .appendingPathExtension(fileExtension)

        // Delete the file if it eists
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try? FileManager.default.removeItem(at: fileURL)
        }
    }
}

extension RequestCache {
    static func retryAll() {
        let requests = RequestCache.all()

        // Iterate over requests and attempt to send
        for request in requests {
            request.send(completion: { (_, _) in
                // Remove file if sent successfully
                RequestCache.remove(request: request)
            }, failure: { (_) in
                // Decrement count and remove if down to 0
                var failedAgainRequest = request
                failedAgainRequest.retryCount -= 1

                if failedAgainRequest.retryCount <= 0 {
                    RequestCache.remove(request: failedAgainRequest)
                } else {
                    RequestCache.store(request: failedAgainRequest)
                }
            })
        }
    }
}
