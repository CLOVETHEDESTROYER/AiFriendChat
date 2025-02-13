import SwiftUI
import StoreKit
import SwiftData

// MARK: - CustomPromptView
struct CustomPromptView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @Query private var savedPrompts: [SavedPrompt]
    @StateObject private var purchaseManager = PurchaseManager.shared
    
    @State private var name = ""
    @State private var prompt = ""
    @State private var persona = ""
    @State private var selectedVoice: VoiceType = .professionalNeutral
    @State private var temperature: Double = 0.7
    
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showingPromptDetail = false
    @State private var selectedPrompt: SavedPrompt?
    
    private let callService = CallService.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color("Color"), Color("Color 2")]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
                
                ScrollView(showsIndicators: true) {
                    VStack(spacing: 20) {
                        createPromptSection
                            .frame(maxWidth: .infinity)
                        
                        if !savedPrompts.isEmpty {
                            Divider()
                                .background(Color.white)
                                .padding(.horizontal)
                            
                            savedPromptsSection
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding()
                    .frame(minHeight: UIScreen.main.bounds.height)
                }
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("Custom Prompts")
            .navigationBarItems(
                leading: Button("Help") {
                    showAlert = true
                    alertTitle = "About Custom Prompts"
                    alertMessage = "Custom prompts allow you to create your own conversation scenarios. These will appear in your scenarios list when making calls."
                },
                trailing: Button("Done") { dismiss() }
            )
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var createPromptSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            TextField("Name", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextEditor(text: $prompt)
                .frame(height: 100)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.5))
                )
            
            TextEditor(text: $persona)
                .frame(height: 100)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2))
                )
            
            Picker("Voice", selection: $selectedVoice) {
                ForEach(VoiceType.allCases, id: \.self) { voice in
                    Text(voice.displayName)
                        .tag(voice)
                }
            }
            .pickerStyle(MenuPickerStyle())
            
            VStack(alignment: .leading) {
                Text("Temperature: \(temperature, specifier: "%.1f")")
                    .foregroundColor(.white)
                Slider(value: $temperature, in: 0.0...1.0, step: 0.1)
            }
            
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Button(action: savePrompt) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Save Prompt")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                }
            }
            .disabled(!isValid || isLoading)
            .padding()
            .background(isValid && !isLoading ? Color.blue : Color.gray)
            .cornerRadius(10)
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
    }
    
    private var savedPromptsSection: some View {
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Custom Scenarios")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Spacer()
                Text("\(savedPrompts.count) total")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 15) {
                    ForEach(Array(savedPrompts.sorted { $0.createdAt > $1.createdAt }.prefix(5))) { prompt in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(prompt.name)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Spacer()
                                Text(prompt.scenarioId != nil ? "✓" : "!")
                                    .foregroundColor(prompt.scenarioId != nil ? .green : .red)
                            }
                            
                            Text(prompt.persona)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                .lineLimit(2)
                            
                            Text("Voice: \(prompt.voiceType.displayName)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding()
                        .frame(width: 280)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(10)
                        .contextMenu {
                            Button(role: .destructive) {
                                modelContext.delete(prompt)
                                try? modelContext.save()
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        
        if savedPrompts.count > 5 {
            Button(action: {
                showingPromptDetail = true
            }) {
                Text("View All Scenarios")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(20)
            }
            .padding(.horizontal)
        }
    }
    
    private var isValid: Bool {
        !name.isEmpty && !prompt.isEmpty && !persona.isEmpty
    }
    
    private func savePrompt() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let scenarioId = try await callService.createCustomScenario(
                    name: name,
                    prompt: prompt,
                    persona: persona,
                    voiceType: selectedVoice,
                    temperature: temperature
                )
                
                await MainActor.run {
                    let newPrompt = SavedPrompt(
                        name: name,
                        prompt: prompt,
                        persona: persona,
                        voiceType: selectedVoice,
                        temperature: temperature
                    )
                    newPrompt.scenarioId = scenarioId
                    modelContext.insert(newPrompt)
                    try? modelContext.save()
                    
                    // Reset form
                    name = ""
                    prompt = ""
                    persona = ""
                    selectedVoice = .professionalNeutral
                    temperature = 0.7
                    isLoading = false
                    
                    // Show success alert
                    alertTitle = "Success"
                    alertMessage = "Custom prompt saved successfully!"
                    showAlert = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    
    private func deletePrompt(_ prompt: SavedPrompt) {
        Task {
            do {
                modelContext.delete(prompt)
                try? modelContext.save()
            } catch {
                errorMessage = error.localizedDescription
                showAlert = true
            }
        }
    }
    
    private func buildPromptList() -> some View {
        ScrollView {
            LazyVStack(spacing: 15) {
                ForEach(savedPrompts) { prompt in
                    SavedPromptCard(prompt: prompt, onDelete: {
                        deletePrompt(prompt)
                    })
                }
            }
        }
        .padding()
    }
    
    private func buildInputSection() -> some View {
        VStack(spacing: 10) {
            TextField("Enter your custom prompt", text: $prompt, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(3...5)
            
            Button(action: savePrompt) {
                Text("Save Prompt")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("highlight"))
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}

struct SavedPromptCard: View {
    let prompt: SavedPrompt
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(prompt.name)
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text(prompt.scenarioId != nil ? "✓" : "!")
                    .foregroundColor(prompt.scenarioId != nil ? .green : .red)
            }
            
            Text("Persona: \(prompt.persona)")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            
            Text("Voice: \(prompt.voiceType.displayName)")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

private struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.black.opacity(0.3))
            .cornerRadius(10)
            .foregroundColor(.white)
    }
}

private struct BackgroundGradient: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color("Color"), Color("Color 2")]),
            startPoint: .top,
            endPoint: .bottom
        )
        .edgesIgnoringSafeArea(.all)
    }
}

private struct PremiumPromptView: View {
    @StateObject private var purchaseManager = PurchaseManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
            
            Text("Premium Feature")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Upgrade to premium to create custom conversation scenarios")
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            PremiumUpgradeButton(purchaseManager: purchaseManager, style: .primary)
            RestorePurchasesButton(purchaseManager: purchaseManager)
        }
        .padding()
    }
}

struct AllPromptsView: View {
    let savedPrompts: [SavedPrompt]
    let modelContext: ModelContext
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(savedPrompts.sorted { $0.createdAt > $1.createdAt }) { prompt in
                    SavedPromptCard(prompt: prompt) {
                        modelContext.delete(prompt)
                        try? modelContext.save()
                    }
                }
            }
            .navigationTitle("All Scenarios")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

#Preview {
    CustomPromptView()
} 
