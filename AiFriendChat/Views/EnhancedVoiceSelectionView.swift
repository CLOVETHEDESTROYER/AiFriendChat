import SwiftUI

struct EnhancedVoiceSelectionView: View {
    @Binding var selectedVoice: VoiceType
    @State private var selectedGender: VoiceGender?
    @State private var selectedAccent: VoiceAccent?
    @State private var selectedPersonality: VoicePersonality?
    @Environment(\.dismiss) var dismiss

    var filteredVoices: [VoiceType] {
        var voices = VoiceType.allCases

        if let gender = selectedGender {
            voices = voices.filter { $0.gender == gender }
        }

        if let accent = selectedAccent {
            voices = voices.filter { $0.accent == accent }
        }

        if let personality = selectedPersonality {
            voices = voices.filter { $0.personality == personality }
        }

        return voices
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Voice Selection")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Choose the perfect voice for your custom scenario")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                // Filter Controls
                VStack(spacing: 12) {
                    // Gender Filter
                    HStack {
                        Text("Gender:")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        HStack(spacing: 8) {
                            ForEach(VoiceGender.allCases, id: \.self) { gender in
                                FilterChip(
                                    title: "\(gender.emoji) \(gender.displayName)",
                                    isSelected: selectedGender == gender,
                                    action: {
                                        if selectedGender == gender {
                                            selectedGender = nil
                                        } else {
                                            selectedGender = gender
                                        }
                                    }
                                )
                            }
                        }
                        Spacer()
                    }

                    // Accent Filter
                    HStack {
                        Text("Accent:")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        HStack(spacing: 8) {
                            ForEach(VoiceAccent.allCases, id: \.self) { accent in
                                FilterChip(
                                    title: "\(accent.emoji) \(accent.displayName)",
                                    isSelected: selectedAccent == accent,
                                    action: {
                                        if selectedAccent == accent {
                                            selectedAccent = nil
                                        } else {
                                            selectedAccent = accent
                                        }
                                    }
                                )
                            }
                        }
                        Spacer()
                    }

                    // Personality Filter
                    HStack {
                        Text("Personality:")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                ForEach(Array(VoicePersonality.allCases.prefix(2)), id: \.self) { personality in
                                    FilterChip(
                                        title: personality.displayName,
                                        isSelected: selectedPersonality == personality,
                                        action: {
                                            if selectedPersonality == personality {
                                                selectedPersonality = nil
                                            } else {
                                                selectedPersonality = personality
                                            }
                                        }
                                    )
                                }
                            }
                            HStack(spacing: 8) {
                                ForEach(Array(VoicePersonality.allCases.suffix(2)), id: \.self) { personality in
                                    FilterChip(
                                        title: personality.displayName,
                                        isSelected: selectedPersonality == personality,
                                        action: {
                                            if selectedPersonality == personality {
                                                selectedPersonality = nil
                                            } else {
                                                selectedPersonality = personality
                                            }
                                        }
                                    )
                                }
                            }
                        }
                        Spacer()
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Clear Filters Button
                if selectedGender != nil || selectedAccent != nil || selectedPersonality != nil {
                    HStack {
                        Button("Clear All Filters") {
                            selectedGender = nil
                            selectedAccent = nil
                            selectedPersonality = nil
                        }
                        .foregroundColor(.blue)
                        .font(.caption)
                        Spacer()
                    }
                }

                // Voice Grid
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        ForEach(filteredVoices, id: \.self) { voice in
                            EnhancedVoiceOptionCard(
                                voice: voice,
                                isSelected: selectedVoice == voice
                            ) {
                                selectedVoice = voice
                            }
                        }
                    }
                }

                if filteredVoices.isEmpty {
                    Text("No voices match your current filters")
                        .foregroundColor(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity)
                }

                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EnhancedVoiceOptionCard: View {
    let voice: VoiceType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(voice.emoji)
                    .font(.largeTitle)

                Text(voice.rawValue.capitalized)
                    .font(.headline)
                    .fontWeight(.medium)

                // Gender and Accent badges
                HStack(spacing: 4) {
                    Text(voice.gender.emoji)
                        .font(.caption)
                    Text(voice.accent.emoji)
                        .font(.caption)
                }

                Text(voice.personality.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Text(voice.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    @State var selectedVoice: VoiceType = .alloy
    return EnhancedVoiceSelectionView(selectedVoice: $selectedVoice)
}
