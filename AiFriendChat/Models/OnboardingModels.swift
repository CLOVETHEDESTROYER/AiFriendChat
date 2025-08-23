//
//  OnboardingModels.swift
//  AiFriendChat
//
//  Created by AI Assistant
//

import Foundation

// MARK: - Mobile Onboarding Models
// These models are designed for the consumer mobile app with simplified onboarding

enum OnboardingStep: String, CaseIterable, Codable {
    case welcome = "welcome"           // Backend now accepts this
    case profile = "profile"           // Backend now accepts this
    case tutorial = "tutorial"         // Backend now accepts this
    case firstCall = "firstCall"       // Backend now accepts this
    
    var title: String {
        switch self {
        case .welcome:
            return "Welcome to AiFriend!"
        case .profile:
            return "Set Up Your Profile"
        case .tutorial:
            return "How It Works"
        case .firstCall:
            return "Make Your First Call"
        }
    }
    
    var description: String {
        switch self {
        case .welcome:
            return "Your AI calling companion for entertainment and fun conversations"
        case .profile:
            return "Tell us a bit about yourself"
        case .tutorial:
            return "Learn how to use your AI friend"
        case .firstCall:
            return "Try it out with a practice call"
        }
    }
    
    var icon: String {
        switch self {
        case .welcome:
            return "👋"
        case .profile:
            return "👤"
        case .tutorial:
            return "🎓"
        case .firstCall:
            return "📞"
        }
    }
}

struct OnboardingStatus: Codable {
    var isComplete: Bool
    var currentStep: OnboardingStep
    var completedSteps: [OnboardingStep]
    var progressPercentage: Double
    
    var nextStep: OnboardingStep? {
        let allSteps = OnboardingStep.allCases
        guard let currentIndex = allSteps.firstIndex(of: currentStep) else { return nil }
        let nextIndex = currentIndex + 1
        return nextIndex < allSteps.count ? allSteps[nextIndex] : nil
    }
}

struct OnboardingProfile: Codable {
    let name: String
    let phoneNumber: String?
    let preferredVoice: String // Voice preference for calls
    let notificationsEnabled: Bool
}

// MARK: - API Request/Response Models

struct OnboardingInitializeRequest: Codable {
    // Mobile app doesn't need complex initialization
    // This will be empty for mobile users
}

struct OnboardingCompleteStepRequest: Codable {
    let step: OnboardingStep
    let data: [String: AnyCodable]? // Flexible data for different steps
}

struct OnboardingStepResponse: Codable {
    let step: OnboardingStep
    let isCompleted: Bool
    let completedAt: String?
    let nextStep: OnboardingStep?
}

// Helper for flexible JSON encoding
struct AnyCodable: Codable {
    let value: Any

    init<T>(_ value: T?) {
        self.value = value ?? ()
    }
}

extension AnyCodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else {
            value = ()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        if let intValue = value as? Int {
            try container.encode(intValue)
        } else if let doubleValue = value as? Double {
            try container.encode(doubleValue)
        } else if let stringValue = value as? String {
            try container.encode(stringValue)
        } else if let boolValue = value as? Bool {
            try container.encode(boolValue)
        }
    }
}
