//
//  EnhancedScenarioSelectionView.swift
//  AiFriendChat
//
//  Created by AI Assistant on 2025-01-16
//

import SwiftUI

struct EnhancedScenarioSelectionView: View {
    @Binding var selectedScenario: String
    @State private var scenarios: [Scenario] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedCategory: String = "all"
    
    private let categories = [
        "all": "All Scenarios",
        "entertainment": "🎭 Entertainment",
        "professional": "💼 Professional",
        "emergency": "🚨 Emergency",
        "romantic": "💕 Romantic",
        "family": "👨‍👩‍👧‍👦 Family",
        "motivational": "🚀 Motivational",
        "celebration": "🎉 Celebration"
    ]
    
    var filteredScenarios: [Scenario] {
        if selectedCategory == "all" {
            return scenarios
        } else {
            return scenarios.filter { $0.category == selectedCategory }
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Category Picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(categories.keys.sorted()), id: \.self) { category in
                        CategoryChip(
                            title: categories[category] ?? category,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = category
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            if isLoading {
                VStack {
                    ProgressView("Loading scenarios...")
                        .padding()
                    Text("Getting the latest scenarios for you...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text("Failed to load scenarios")
                        .font(.headline)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        loadScenarios()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Scenarios Grid
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                        ForEach(filteredScenarios) { scenario in
                            ScenarioCard(
                                scenario: scenario,
                                isSelected: selectedScenario == scenario.id
                            ) {
                                selectedScenario = scenario.id
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                if filteredScenarios.isEmpty {
                    VStack {
                        Image(systemName: "magnifyingglass")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No scenarios in this category")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Try selecting a different category above")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            loadScenarios()
        }
        .refreshable {
            await refreshScenarios()
        }
    }
    
    private func loadScenarios() {
        isLoading = true
        errorMessage = nil
        
        Task {
            await refreshScenarios()
        }
    }
    
    private func refreshScenarios() async {
        do {
            let loadedScenarios = try await BackendService.shared.getScenarios()
            await MainActor.run {
                self.scenarios = loadedScenarios
                self.isLoading = false
                
                // Set default scenario if none selected
                if self.selectedScenario.isEmpty && !loadedScenarios.isEmpty {
                    self.selectedScenario = loadedScenarios.first?.id ?? "default"
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ScenarioCard: View {
    let scenario: Scenario
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Text(scenario.icon)
                    .font(.system(size: 40))
                
                Text(scenario.name)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                Text(scenario.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                
                HStack {
                    // Family Friendly Badge
                    if let isFamilyFriendly = scenario.is_family_friendly, isFamilyFriendly {
                        Text("👨‍👩‍👧‍👦 Family")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    } else if let isFamilyFriendly = scenario.is_family_friendly, !isFamilyFriendly {
                        Text("⚠️ Mature")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    
                    Spacer()
                }
                
                if let voice = scenario.recommended_voice {
                    Text("🎵 Voice: \(voice)")
                        .font(.caption2)
                        .foregroundColor(.blue)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 180)
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EnhancedScenarioSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        EnhancedScenarioSelectionView(selectedScenario: .constant("default"))
    }
}
