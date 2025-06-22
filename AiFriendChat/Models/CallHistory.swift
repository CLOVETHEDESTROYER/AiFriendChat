import Foundation
import SwiftData
import SwiftUI

@Model
final class CallHistory {
    var id: UUID
    var phoneNumber: String
    var scenario: String
    var timestamp: Date
    var status: CallStatus
    
    init(phoneNumber: String, scenario: String, status: CallStatus) {
        self.id = UUID()
        self.phoneNumber = phoneNumber
        self.scenario = scenario
        self.timestamp = Date()
        self.status = status
    }
}

enum CallStatus: String, Codable {
    case completed = "Completed"
    case failed = "Failed"
    case cancelled = "Cancelled"
    
    var color: Color {
        switch self {
        case .completed:
            return .green
        case .failed:
            return .red
        case .cancelled:
            return .orange
        }
    }
} 
