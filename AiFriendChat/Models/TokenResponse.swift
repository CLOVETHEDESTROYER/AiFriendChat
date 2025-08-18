//
//  TokenResponse.swift
//  AiFriendChat
//
//  Created by Carlos Alvarez on 10/19/24.
//


// Models/TokenResponse.swift
struct TokenResponse: Codable {
    let accessToken: String
    let refreshToken: String?  // Make optional since backend might not return it
    let tokenType: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
    }
}

