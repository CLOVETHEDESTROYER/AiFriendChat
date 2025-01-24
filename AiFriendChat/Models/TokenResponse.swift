// Models/TokenResponse.swift
struct TokenResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
    }
}

// Models/CallSchedule.swift
struct CallSchedule: Codable, Identifiable {
    let id: String
    let phoneNumber: String
    let scheduledTime: Date
    let scenario: String
}
