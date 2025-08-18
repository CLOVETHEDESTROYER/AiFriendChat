import SwiftUI
import SwiftData
import os.log

struct CallView: View {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.app", category: "CallView")
    
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: HomeViewModel
    @StateObject private var callViewModel: CallViewModel
    @StateObject private var purchaseManager = PurchaseManager.shared
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    @State private var phoneNumber = ""
    @State private var selectedScenario = "default"
    @State private var userName = ""
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showAlert = false
    @State private var showScheduleSheet = false
    @State private var showAuthPrompt = false
    @State private var showAuthView = false
    
    @FocusState private var activeField: Field?
    
    private enum Field: Hashable {
        case userName, phoneNumber
    }
    
    // Enhanced scenario collection with all available premade scenarios
    // Updated to match actual backend scenarios from MCP testing
    var allPremadeScenarios: [String] {
        return [
            // Emergency Exit scenarios
            "fake_doctor",           // Emergency exit with medical urgency
            "fake_tech_support",     // Security breach emergency  
            "fake_car_accident",     // Minor accident drama
            
            // Work Exit scenarios
            "fake_boss",             // Work emergency for quick escape
            
            // Social Exit scenarios  
            "fake_restaurant_manager", // Special reservation confirmation
            
            // Fun Interaction scenarios
            "fake_celebrity",         // Chat with a famous person
            "fake_lottery_winner",    // You've won big!
            
            // Social Interaction scenarios
            "fake_dating_app_match",  // Meet your new match
            "fake_old_friend",        // Reconnect with someone from the past
            "fake_news_reporter"      // Interview opportunity
        ]
    }
    
    var scenarios: [String] {
        var allScenarios = allPremadeScenarios
        
        if purchaseManager.isSubscribed {
            if let data = UserDefaults.standard.data(forKey: "savedCustomPrompts"),
               let customPrompts = try? JSONDecoder().decode([SavedPrompt].self, from: data) {
                allScenarios.append(contentsOf: customPrompts.map { "custom_\($0.name)" })
            }
        }
        
        return allScenarios
    }
    
    // Organize scenarios into pages for swiping (6 per page)
    var scenarioPages: [[String]] {
        let itemsPerPage = 6
        var pages: [[String]] = []
        let allScenarios = scenarios
        
        for i in stride(from: 0, to: allScenarios.count, by: itemsPerPage) {
            let endIndex = min(i + itemsPerPage, allScenarios.count)
            pages.append(Array(allScenarios[i..<endIndex]))
        }
        
        return pages
    }
    
    init(modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: HomeViewModel(modelContext: modelContext))
        _callViewModel = StateObject(wrappedValue: CallViewModel(modelContext: modelContext))
    }
    
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
                    VStack(spacing: 15) {
                        // Welcome Title
                        Text("Welcome to AI Friend Chat")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.top, 10)
                        
                        // Trial Status in a more compact form
                        if !purchaseManager.isSubscribed {
                            HStack {
                                Text(purchaseManager.isSubscribed ? 
                                     "Call Time: \(purchaseManager.getRemainingTimeDisplay())" : 
                                     "Trial Calls: \(purchaseManager.getRemainingTrialCalls())")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                Spacer()
                                Button("Restore") {
                                    Task {
                                        try? await purchaseManager.restorePurchases()
                                    }
                                }
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                            }
                            .padding(.horizontal)
                            
                            PremiumUpgradeButton(purchaseManager: purchaseManager, style: .secondary)
                                .padding(.horizontal)
                                .padding(.bottom, 5)
                        }
                        
                        // User Name Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Name")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            TextField("Enter your name", text: $userName)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(10)
                                .focused($activeField, equals: .userName)
                            
                            Button(action: updateUserName) {
                                Text("Update Name")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .background(Color("highlight"))
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Phone Number Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Phone Number")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            TextField("Enter phone number", text: $phoneNumber)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(10)
                                .keyboardType(.phonePad)
                                .focused($activeField, equals: .phoneNumber)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(phoneNumber.isEmpty ? Color.red.opacity(0.7) : Color.clear, lineWidth: 1)
                                )
                            
                            if phoneNumber.isEmpty {
                                Text("Phone number is required")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.leading, 4)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Enhanced Swipeable Scenario Selection
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Text("Select Scenario")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Text("Swipe for more →")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .padding(.horizontal)
                            
                            TabView {
                                ForEach(Array(scenarioPages.enumerated()), id: \.offset) { pageIndex, pageScenarios in
                                    LazyVGrid(columns: [
                                        GridItem(.flexible()),
                                        GridItem(.flexible()),
                                        GridItem(.flexible())
                                    ], spacing: 15) {
                                        ForEach(pageScenarios, id: \.self) { scenario in
                                            Button(action: { selectedScenario = scenario }) {
                                                VStack(spacing: 8) {
                                                    // Scenario Icon
                                                    Image(systemName: getScenarioIcon(for: scenario))
                                                        .resizable()
                                                        .frame(width: 24, height: 24)
                                                        .foregroundColor(selectedScenario == scenario ? .white : .black)
                                                    
                                                    Text(displayName(for: scenario))
                                                        .font(.system(size: 11, weight: .medium))
                                                        .foregroundColor(selectedScenario == scenario ? .white : .black)
                                                        .multilineTextAlignment(.center)
                                                        .lineLimit(2)
                                                }
                                                .frame(height: 75)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 6)
                                                .background(selectedScenario == scenario ? Color("highlight") : Color.white.opacity(0.9))
                                                .cornerRadius(10)
                                            }
                                        }
                                        
                                        // Fill empty spots in the grid if needed
                                        ForEach(pageScenarios.count..<6, id: \.self) { _ in
                                            Color.clear
                                                .frame(height: 75)
                                        }
                                    }
                                    .padding(.horizontal)
                                    .tag(pageIndex)
                                }
                            }
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                            .frame(height: 180)
                        }
                        
                        // Call Button
                        Button(action: makeCall) {
                            HStack {
                                Image(systemName: "phone.fill")
                                Text("Start Call")
                            }
                            .font(.headline)
                            .foregroundColor(phoneNumber.isEmpty ? .gray : .white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(phoneNumber.isEmpty ? Color("highlight").opacity(0.5) : Color("highlight"))
                            .cornerRadius(15)
                            .padding(.horizontal)
                        }
                        .disabled(phoneNumber.isEmpty || callViewModel.isCallInProgress)
                        .overlay {
                            if callViewModel.isCallInProgress {
                                ProgressView()
                                    .tint(.white)
                            }
                        }
                        .shake(phoneNumber.isEmpty && showAlert)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .keyboard) {
                    Button("Done") {
                        activeField = nil
                    }
                }
                
                #if DEBUG
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu("Debug") {
                        if purchaseManager.isSubscribed {
                            Button("🔴 DISABLE Debug Premium") {
                                purchaseManager.toggleDebugPremium()
                            }
                        } else {
                            Button("🟡 ENABLE Debug Premium") {
                                purchaseManager.toggleDebugPremium()
                            }
                        }
                        
                        Button("Reset Call Count") {
                            UserDefaults.standard.removeObject(forKey: "callsMadeCount")
                            purchaseManager.objectWillChange.send()
                        }
                        
                        Button("Add Test Call") {
                            let currentCalls = UserDefaults.standard.integer(forKey: "callsMadeCount")
                            UserDefaults.standard.set(currentCalls + 1, forKey: "callsMadeCount")
                            purchaseManager.objectWillChange.send()
                        }
                        
                        Divider()
                        
                        Text("Status:")
                            .font(.caption.bold())
                        Text("Debug Premium: \(purchaseManager.isSubscribed ? "🟢 ON" : "🔴 OFF")")
                            .font(.caption)
                        Text("Calls Made: \(purchaseManager.callsMade)")
                            .font(.caption)
                        Text("Endpoint: /mobile/make-call")
                            .font(.caption)
                    }
                }
                #endif
            }
            .sheet(isPresented: $showScheduleSheet) {
                ScheduleCallView(phoneNumber: phoneNumber, scenario: selectedScenario)
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .onChange(of: callViewModel.errorMessage) { oldValue, newValue in
                if let error = newValue {
                    alertTitle = "Error"
                    alertMessage = error
                    showAlert = true
                }
            }
            .onChange(of: callViewModel.successMessage) { oldValue, newValue in
                if let success = newValue {
                    alertTitle = "Success"
                    alertMessage = success
                    showAlert = true
                }
            }
            .onChange(of: callViewModel.authenticationRequired) { _, authRequired in
                if authRequired {
                    // Clear the flag and show auth prompt
                    callViewModel.authenticationRequired = false
                    authViewModel.isLoggedIn = false
                    showAuthPrompt = true
                }
            }
            .onChange(of: callViewModel.showPremiumPrompt) { _, showPrompt in
                if showPrompt {
                    // Reset the flag and show upgrade prompt
                    callViewModel.showPremiumPrompt = false
                    callViewModel.upgradeMessage = callViewModel.premiumPromptMessage
                    callViewModel.showUpgradePrompt = true
                }
            }
            .sheet(isPresented: $showAuthPrompt) {
                AuthPromptView(showAuthView: $showAuthView)
            }
            .fullScreenCover(isPresented: $showAuthView) {
                AuthView()
            }
        }
    }
    
    private func makeCall() {
        guard !phoneNumber.isEmpty else {
            alertTitle = "Error"
            alertMessage = "Please enter a phone number."
            showAlert = true
            return
        }
        
        // Check authentication before making call
        if !authViewModel.isLoggedIn {
            showAuthPrompt = true
            return
        }
        
        callViewModel.initiateCall(phoneNumber: phoneNumber, scenario: selectedScenario)
    }
    
    private func updateUserName() {
        logger.debug("Starting updateUserName function")
        let trimmedName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            logger.error("Attempted to update with empty username")
            alertTitle = "Error"
            alertMessage = "Name cannot be empty."
            showAlert = true
            return
        }
        
        Task {
            do {
                let message = try await viewModel.updateUserName(to: trimmedName)
                logger.debug("Successfully updated username: \(message)")
                alertTitle = "Success"
                alertMessage = message
                UserDefaults.standard.set(trimmedName, forKey: "userName")
            } catch {
                logger.error("Failed to update username: \(error.localizedDescription)")
                alertTitle = "Error"
                alertMessage = "Failed to update name: \(error.localizedDescription)"
            }
            showAlert = true
        }
    }
    
    private func displayName(for scenario: String) -> String {
        if scenario.hasPrefix("custom_") {
            return "Custom: " + scenario.replacingOccurrences(of: "custom_", with: "")
        }
        
        // Enhanced display names for better UX
        switch scenario {
        case "default": return "Friendly Chat"
        case "celebrity": return "Celebrity Talk"
        case "comedian": return "Comedy Call"
        case "storyteller": return "Story Time"
        case "yacht_party": return "Party Host"
        case "instigator": return "Drama Starter"
        case "sales_pitch": return "Sales Call"
        case "customer_service": return "Support"
        case "real_estate": return "Real Estate"
        case "sister_emergency": return "Sister Help"
        case "mother_emergency": return "Mom Help"
        case "caring_partner": return "Partner"
        case "surprise_date_planner": return "Date Planner"
        case "long_distance_love": return "Long Distance"
        case "supportive_bestie": return "Best Friend"
        case "encouraging_parent": return "Parent"
        case "caring_sibling": return "Sibling"
        case "therapist": return "Life Coach"
        case "motivational_coach": return "Motivator"
        case "wellness_checkin": return "Wellness"
        case "celebration_caller": return "Celebration"
        case "birthday_wishes": return "Birthday"
        case "gratitude_caller": return "Gratitude"
        default:
            return scenario.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
    
    private func getScenarioIcon(for scenario: String) -> String {
        if scenario.hasPrefix("custom_") {
            return "text.bubble.fill"
        }
        
        // Category-based icons for better visual organization
        switch scenario {
        // Entertainment
        case "default": return "message.circle.fill"
        case "celebrity": return "star.circle.fill"
        case "comedian": return "theatermasks.fill"
        case "storyteller": return "book.circle.fill"
        case "yacht_party": return "sailboat.fill"
        case "instigator": return "exclamationmark.triangle.fill"
        
        // Professional
        case "sales_pitch": return "briefcase.fill"
        case "customer_service": return "headphones.circle.fill"
        case "real_estate": return "house.circle.fill"
        
        // Emergency
        case "sister_emergency", "mother_emergency": return "cross.circle.fill"
        
        // Romantic
        case "caring_partner", "surprise_date_planner", "long_distance_love": return "heart.circle.fill"
        
        // Family & Friends
        case "supportive_bestie", "encouraging_parent", "caring_sibling": return "person.2.circle.fill"
        
        // Motivational
        case "therapist", "motivational_coach", "wellness_checkin": return "brain.head.profile"
        
        // Celebration
        case "celebration_caller", "birthday_wishes", "gratitude_caller": return "party.popper.fill"
        
        default:
            return "hexagon.fill"
        }
    }
}

// Add shake animation modifier
extension View {
    func shake(_ shake: Bool) -> some View {
        modifier(ShakeEffect(shake: shake))
    }
}

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var shake: Bool
    
    var animatableData: CGFloat {
        get { CGFloat(shake ? 1 : 0) }
        set { _ = newValue }
    }
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        guard shake else { return ProjectionTransform(.identity) }
        
        let translation = amount * sin(animatableData * .pi * CGFloat(shakesPerUnit))
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}

