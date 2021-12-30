import Foundation

@objc public class Person: NSObject, Encodable {
    let name: String?
    let email: String?
    let phoneNumber: String?

    @objc public init(name: String? = nil, email: String? = nil, phoneNumber: String? = nil) {
        self.name = name
        self.email = email
        self.phoneNumber = phoneNumber
    }
}
