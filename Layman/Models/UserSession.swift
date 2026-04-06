import Foundation

struct UserSession: Codable, Equatable {
    let accessToken: String
    let refreshToken: String?
    let userID: UUID
    let email: String
}
