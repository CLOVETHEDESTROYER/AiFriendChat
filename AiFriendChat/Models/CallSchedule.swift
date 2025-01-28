//
//  CallSchedule.swift
//  AiFriendChat
//
//  Created by Carlos Alvarez on 10/19/24.
//

import Foundation
import SwiftData

@available(iOS 17, *)
@Model
final class CallSchedule: Codable {
    @Attribute(.unique) var id: Int
    var phoneNumber: String
    var scheduledTime: Date
    var scenario: String
    var createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case phoneNumber = "phone_number"
        case scheduledTime = "scheduled_time"
        case scenario
        case createdAt = "created_at"
    }
    
    init(id: Int = 0, phoneNumber: String, scheduledTime: Date, scenario: String, createdAt: Date? = nil) {
        self.id = id
        self.phoneNumber = phoneNumber
        self.scheduledTime = scheduledTime
        self.scenario = scenario
        self.createdAt = createdAt
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        phoneNumber = try container.decode(String.self, forKey: .phoneNumber)
        scheduledTime = try container.decode(Date.self, forKey: .scheduledTime)
        scenario = try container.decode(String.self, forKey: .scenario)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(phoneNumber, forKey: .phoneNumber)
        try container.encode(scheduledTime, forKey: .scheduledTime)
        try container.encode(scenario, forKey: .scenario)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
    }
}
