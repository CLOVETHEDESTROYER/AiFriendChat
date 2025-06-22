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

enum VoiceType: String, CaseIterable, Codable {
    case aggressiveMale = "aggressive_male"
    case concernedFemale = "concerned_female"
    case elderlyFemale = "elderly_female"
    case professionalNeutral = "professional_neutral"
    case gentleSupportive = "gentle_supportive"
    case warmEngaging = "warm_engaging"
    case deepAuthoritative = "deep_authoritative"
    case energeticUpbeat = "energetic_upbeat"
    case clearOptimistic = "clear_optimistic"
    
    var displayName: String {
        switch self {
        case .aggressiveMale: return "Aggressive Male"
        case .concernedFemale: return "Concerned Female"
        case .elderlyFemale: return "Elderly Female"
        case .professionalNeutral: return "Professional Neutral"
        case .gentleSupportive: return "Gentle Supportive"
        case .warmEngaging: return "Warm Engaging"
        case .deepAuthoritative: return "Deep Authoritative"
        case .energeticUpbeat: return "Energetic Upbeat"
        case .clearOptimistic: return "Clear Optimistic"
        }
    }
    
    var description: String {
        switch self {
        case .aggressiveMale: return "Strong, assertive tone"
        case .concernedFemale: return "Caring, empathetic voice"
        case .elderlyFemale: return "Wise, experienced tone"
        case .professionalNeutral: return "Balanced, business-like"
        case .gentleSupportive: return "Soft, encouraging voice"
        case .warmEngaging: return "Friendly, conversational"
        case .deepAuthoritative: return "Commanding, confident"
        case .energeticUpbeat: return "Lively, enthusiastic"
        case .clearOptimistic: return "Bright, positive tone"
        }
    }
} 