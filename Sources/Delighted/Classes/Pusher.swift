import Starscream
import Foundation

private let encoder: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    return encoder
}()

private let decoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return decoder
}()

public struct PusherAuthRequest: Encodable {
    let surveyRequestToken: String
    let socketId: String
    let channelName: String
}

private struct PusherAuthResponse: Decodable {
    let auth: String
}

/// Managest pusher authentication and state with websockets
class Pusher {

    let websocketURL: URL
    let baseAPIURL: URL
    let channelName: String
    let surveyRequestToken: String
    let socket: WebSocket

    var subscribed = false
    var clientTypingLastSent: Date?
    var numberOfClientTypingsSent = 0

    public init(websocketURL: URL, baseAPIURL: URL, channelName: String, surveyRequestToken: String) {
        self.websocketURL = websocketURL
        self.baseAPIURL = baseAPIURL
        self.channelName = channelName
        self.surveyRequestToken = surveyRequestToken
        socket = WebSocket(request: URLRequest(url: websocketURL))
        socket.delegate = self
    }
}

extension Pusher {
    public func connect() {
        socket.connect()
    }

    public func disconnect() {
        subscribed = false
        socket.disconnect()
    }

    func sendClientTyping() {
        // ONly send events when subscribed
        guard subscribed else {
            Logger.log(.error, "Can't send event to pusher - not subsubscribed")
            return
        }

        // Only low max of 1000 events
        guard self.numberOfClientTypingsSent < 1000 else {
            Logger.log(.debug, "Sent over 1000 pusher client typing events")
            return
        }

        // Prevent sending events within 2 seconds of each other
        guard (clientTypingLastSent ?? Date.distantPast).timeIntervalSinceNow < -2 else {
            Logger.log(.debug, "Can't send event to pusher - need to wait 2 seconds")
            return
        }

        // Sets last typing to now
        // Increments number of events sent
        // Encoding event to write to socket
        self.clientTypingLastSent = Date()
        self.numberOfClientTypingsSent += 1

        let event = Event(event: .clientTyping, channel: self.channelName, data: [
            "survey_request_token": self.surveyRequestToken
            ])
        if let data = try? encoder.encode(event) {
            socket.write(data: data)
            Logger.log(.debug, "Sent client typing event to pusher")
        }
    }
}

private extension Pusher {
    /// State machine from received websocket events
    ///
    /// - Parameter event: Event receeived from websocket/pusher
    func handleEvent(event: Event) {
        switch event.event {
        // Gets authorization from Delighted API for pusher when socket is connected
        case .connectionEstablished:
            if let socketId = event.data.data["socket_id"] {
                authorize(socketId: socketId)
            }
        // Sets boolean for when successfully subscribed
        case .subscriptionSucceeded:
            Logger.log(.debug, "Pusher subscription succeeded")
            subscribed = true
        case .subscribe, .clientTyping:
            break
        }
    }

    func authorize(socketId: String) {
        // Create pusher auth body
        let pusherAuthBody = PusherAuthRequest(
            surveyRequestToken: self.surveyRequestToken,
            socketId: socketId,
            channelName: self.channelName
        )

        // Sends request to get pusher auth
        let route = Route.pusherAuth(pusherAuthRequest: pusherAuthBody)
        let request = try? Request(baseURL: baseAPIURL, route: route)
        request?.send(completion: { [weak self] (data, _) in
            guard let data = data else {
                Logger.log(.error, "No data received from push auth response")
                return
            }

            // Decodes with PusherAuthResponse
            do {
                let pusherAuthResponse = try decoder.decode(PusherAuthResponse.self, from: data)
                self?.subscribe(pusherAuthResponse: pusherAuthResponse)
            } catch {
                Logger.log(.error, "Could not decode push auth response \(error.localizedDescription)")
            }
        }, failure: { (error) in
            Logger.log(.error, "Error sending push auth request \(error.localizedDescription)")
        })
    }

    func subscribe(pusherAuthResponse: PusherAuthResponse) {
        let event = Event(event: .subscribe, data: [
            "auth": pusherAuthResponse.auth,
            "channel": channelName
            ])

        if let data = try? encoder.encode(event) {
            socket.write(data: data)
        }
    }
}

extension Pusher: WebSocketDelegate {
    func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .text(let text):
            guard let data = text.data(using: .utf8) else {
                Logger.log(.error, "Invalid data from pusher")
                return
            }

            do {
                let event = try decoder.decode(Event.self, from: data)
                handleEvent(event: event)
            } catch {
                Logger.log(.error, "Error decoding pusher message: \(error.localizedDescription)")
            }
        default:
            break
        }
    }
}

/// Event that is sent and received from the websocket
private struct Event: Codable {
    enum EventType: String, Codable {
        case connectionEstablished = "pusher:connection_established"
        case subscribe = "pusher:subscribe"
        case subscriptionSucceeded = "pusher_internal:subscription_succeeded"
        case clientTyping = "client-typing"
    }

    let event: EventType
    let channel: String?
    let data: EventData

    init(event: EventType, channel: String? = nil, data: [String: String]) {
        self.event = event
        self.channel = channel
        self.data = EventData(data: data)
    }
}

struct EventData {
    /// Error that gets thrown when Event decoding error occurs
    struct EventDataDecodingError: Error {
    }

    let data: [String: String]

    init(data: [String: String]) {
        self.data = data
    }
}

// Websocket sends the "data" value back as a JSON encoded string
// Decodes the string to [String: String]
extension EventData: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let dataRaw = try container.decode(String.self)

        if let data = dataRaw.data(using: .utf8) {
            self.data = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String] ?? [:]
        } else {
            throw EventDataDecodingError()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(data)
    }
}
