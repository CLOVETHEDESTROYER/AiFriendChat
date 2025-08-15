import Foundation
import SwiftData

@Model
final class SavedPrompt: Codable {
    var id: UUID
    var name: String
    var prompt: String
    var persona: String
    var voiceType: VoiceType
    var temperature: Double
    var scenarioId: String?
    var createdAt: Date
    
    init(name: String, prompt: String, persona: String, voiceType: VoiceType, temperature: Double) {
        self.id = UUID()
        self.name = name
        self.prompt = prompt
        self.persona = persona
        self.voiceType = voiceType
        self.temperature = temperature
        self.createdAt = Date()
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case prompt
        case persona
        case voiceType
        case temperature
        case scenarioId
        case createdAt
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        prompt = try container.decode(String.self, forKey: .prompt)
        persona = try container.decode(String.self, forKey: .persona)
        voiceType = try container.decode(VoiceType.self, forKey: .voiceType)
        temperature = try container.decode(Double.self, forKey: .temperature)
        scenarioId = try container.decodeIfPresent(String.self, forKey: .scenarioId)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(prompt, forKey: .prompt)
        try container.encode(persona, forKey: .persona)
        try container.encode(voiceType, forKey: .voiceType)
        try container.encode(temperature, forKey: .temperature)
        try container.encodeIfPresent(scenarioId, forKey: .scenarioId)
        try container.encode(createdAt, forKey: .createdAt)
    }
}

// MARK: - Enhanced Voice System (OpenAI Voices with Gender/Accent Classification)

enum VoiceType: String, CaseIterable, Codable {
    case alloy = "alloy"
    case ash = "ash"
    case ballad = "ballad"
    case coral = "coral"
    case echo = "echo"
    case sage = "sage"
    case shimmer = "shimmer"
    case verse = "verse"

    var displayName: String {
        switch self {
        case .alloy: return "Female, Warm"
        case .ash: return "Male, Energetic"
        case .ballad: return "Male, British"
        case .coral: return "Female, Gentle"
        case .echo: return "Male, Professional"
        case .sage: return "Female, Wise"
        case .shimmer: return "Female, Excited"
        case .verse: return "Male, Warm"
        }
    }
    
    var gender: VoiceGender {
        switch self {
        case .alloy, .coral, .sage, .shimmer:
            return .female
        case .ash, .ballad, .echo, .verse:
            return .male
        }
    }

    var accent: VoiceAccent {
        switch self {
        case .ballad:
            return .british
        case .alloy, .ash, .coral, .echo, .sage, .shimmer, .verse:
            return .american
        }
    }

    var personality: VoicePersonality {
        switch self {
        case .alloy: return .warm_engaging
        case .ash: return .energetic_upbeat
        case .ballad: return .professional_neutral
        case .coral: return .gentle_supportive
        case .echo: return .professional_neutral
        case .sage: return .gentle_supportive
        case .shimmer: return .energetic_upbeat
        case .verse: return .warm_engaging
        }
    }

    var description: String {
        switch self {
        case .alloy: return "Warm and engaging female voice"
        case .ash: return "Energetic and upbeat male voice"
        case .ballad: return "Professional British male voice"
        case .coral: return "Gentle and supportive female voice"
        case .echo: return "Clear and professional male voice"
        case .sage: return "Calm and wise female voice"
        case .shimmer: return "Excited and enthusiastic female voice"
        case .verse: return "Warm and engaging male voice"
        }
    }

    var emoji: String {
        switch self {
        case .alloy: return "😊"
        case .ash: return "🎉"
        case .ballad: return "🇬🇧"
        case .coral: return "🤗"
        case .echo: return "💼"
        case .sage: return "🧘‍♀️"
        case .shimmer: return "✨"
        case .verse: return "😊"
        }
    }
}

enum VoiceGender: String, CaseIterable, Codable {
    case male = "male"
    case female = "female"

    var displayName: String {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
        }
    }

    var emoji: String {
        switch self {
        case .male: return "👨"
        case .female: return "👩"
        }
    }
}

enum VoiceAccent: String, CaseIterable, Codable {
    case american = "american"
    case british = "british"

    var displayName: String {
        switch self {
        case .american: return "American"
        case .british: return "British"
        }
    }

    var emoji: String {
        switch self {
        case .american: return "🇺🇸"
        case .british: return "🇬🇧"
        }
    }
}

enum VoicePersonality: String, CaseIterable, Codable {
    case warm_engaging = "warm_engaging"
    case energetic_upbeat = "energetic_upbeat"
    case gentle_supportive = "gentle_supportive"
    case professional_neutral = "professional_neutral"

    var displayName: String {
        switch self {
        case .warm_engaging: return "Warm & Engaging"
        case .energetic_upbeat: return "Energetic & Upbeat"
        case .gentle_supportive: return "Gentle & Supportive"
        case .professional_neutral: return "Professional & Neutral"
        }
    }
} 