import SwiftUI
import SwiftData
import os.log // Add this import at the top

struct HomeView: View {
    // Add logger as a private property at the top of your HomeView
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.app", category: "HomeView")
    
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: HomeViewModel
    @StateObject private var callViewModel = CallViewModel()
    @State private var phoneNumber = ""
    @State private var selectedScenario = "default"
    @State private var userName = ""
    @State private var isUpdatingName = false

    // Notification state variables
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showAlert = false
    @State private var showPremiumAlert = false // Added for premium alert

    
    // To track active TextField
    @FocusState private var activeField: Field?
    
    // Scenarios list
    var scenarios: [String] {
        ["default", "sister_emergency", "mother_emergency", "yacht_party", "instigator", "gameshow_host"]
    }
    
    // Enum to track the current active field
    private enum Field: Hashable {
        case userName, phoneNumber
    }
    
    @StateObject private var purchaseManager = PurchaseManager.shared
    @State private var showSubscriptionAlert = false
    @State private var showSubscriptionPrompt = false

    // Add these state variables
    @State private var showAccountSheet = false
    @State private var showSettingsSheet = false
    @State private var showHelpSheet = false
    @State private var showCallHistory = false

    init(modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: HomeViewModel(modelContext: modelContext))
        _callViewModel = StateObject(wrappedValue: CallViewModel())
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Gradient background
                LinearGradient(
                    gradient: Gradient(colors: [Color("Color 1"), Color("Color 2")]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    // Header
                    Text("Welcome to AI Friend Chat")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                        .padding()
                    
                    // Trial Status
                    if !purchaseManager.isSubscribed{
                        Text("Trial Calls Remaining: \(purchaseManager.getRemainingTrialCalls())")
                            .font(.subheadline)
                            .foregroundColor(.black)
                            .padding(.horizontal)
                    }
                    
                    // User Name Input
                    TextField("Enter your name", text: $userName)
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(15)
                        .padding(.horizontal, 20)
                        .focused($activeField, equals: .userName)
                        .autocapitalization(.words)
                        .toolbar {
                            ToolbarItem(placement: .keyboard) {
                                Button("Done") {
                                    hideKeyboard()
                                }
                            }
                        }
                    
                    // Update Name Button
                    Button(action: {
                        updateUserName()
                    }) {
                        HStack {
                            Image(systemName: "person.fill.checkmark")
                            Text("Update Name")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color("highlight"))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal, 20)
                    
                    // Phone Number Input
                    TextField("Enter phone number", text: $phoneNumber)
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(15)
                        .padding(.horizontal, 20)
                        .keyboardType(.phonePad)
                        .focused($activeField, equals: .phoneNumber)
                        .toolbar {
                            ToolbarItem(placement: .keyboard) {
                                Button("Done") {
                                    hideKeyboard()
                                }
                            }
                        }
                    
                    // Scenario Picker Section
                    VStack(spacing: 10) {
                        Text("Select a Scenario")
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding(.bottom, 10)
                        
                        let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
                        
                        LazyVGrid(columns: columns, spacing: 15) {
                            ForEach(scenarios, id: \.self) { scenario in
                                Button(action: {
                                    selectedScenario = scenario
                                }) {
                                    VStack {
                                        Image(systemName: "hexagon.fill")
                                            .resizable()
                                            .frame(width: 30, height: 30)
                                            .foregroundColor(selectedScenario == scenario ? .white : .black)
                                            .scaleEffect(selectedScenario == scenario ? 1.2 : 1.0)
                                            .animation(.spring(), value: selectedScenario)
                                        
                                        Text(scenario.replacingOccurrences(of: "_", with: " ").capitalized)
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(selectedScenario == scenario ? .white : .black)
                                            .multilineTextAlignment(.center)
                                    }
                                    .padding()
                                    .frame(width: 100, height: 100)
                                    .background(selectedScenario == scenario ? Color("highlight") : Color.white.opacity(0.8))
                                    .cornerRadius(15)
                                    .shadow(color: .gray.opacity(0.5), radius: 5, x: 0, y: 2)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Action Buttons
                    VStack(spacing: 15) {
                        Button(action: {
                            makeImmediateCall()
                        }) {
                            HStack {
                                Image(systemName: "phone.arrow.up.right")
                                Text("Make Immediate Call")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color("highlight"))
                            .cornerRadius(10)
                        }
                        .disabled(phoneNumber.isEmpty || callViewModel.isCallInProgress)
                        
                        NavigationLink(
                            destination: ScheduleCallView(phoneNumber: phoneNumber, scenario: selectedScenario)
                        ) {
                            HStack {
                                Image(systemName: "calendar.badge.plus")
                                Text("Schedule Call")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(purchaseManager.isSubscribed ? Color("AccentColor") : Color.gray)
                            .cornerRadius(10)
                        }
                        .disabled(!purchaseManager.isSubscribed)
                        .onTapGesture {
                            if !purchaseManager.isSubscribed {
                                showSubscriptionPrompt = true
                            }
                        }
                        
                        if !purchaseManager.isSubscribed {
                            Button(action: {
                                showSubscriptionAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "star.fill")
                                    Text("Upgrade to Premium")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.yellow)
                                .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .navigationTitle("")
                .navigationBarItems(
                    leading: Button("Logout") {
                        authViewModel.logout()
                    }
                )
                .onTapGesture {
                    hideKeyboard()
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .alert("Upgrade to Premium", isPresented: $showSubscriptionAlert) {
                if let product = purchaseManager.products.first {
                    Button("Subscribe (\(product.priceLocale.currencySymbol ?? "$")\(product.price))", role: .none) {
                        purchaseManager.purchase(product: product)
                    }
                    Button("Restore Purchases", role: .none) {
                        purchaseManager.restorePurchases()
                    }
                    Button("Cancel", role: .cancel) {}
                }
            } message: {
                Text("Get unlimited calls and scheduling features!")
            }
            .alert("Premium Feature", isPresented: $showPremiumAlert) {
                Button("Subscribe", role: .none) {
                    showSubscriptionAlert = true
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Call scheduling is available for premium subscribers only.")
            }
            .alert("Upgrade to Premium", isPresented: $showSubscriptionPrompt) {
                Button("View Premium Features", role: .none) {
                    showSubscriptionAlert = true
                }
                Button("Maybe Later", role: .cancel) {}
            } message: {
                Text("Schedule calls and get unlimited immediate calls with our premium subscription!")
            }
            .onChange(of: callViewModel.errorMessage) { newValue in
                if let error = newValue {
                    alertTitle = "Error"
                    alertMessage = error
                    showAlert = true
                }
            }
            .onChange(of: callViewModel.successMessage) { newValue in
                if let success = newValue {
                    alertTitle = "Success"
                    alertMessage = success
                    showAlert = true
                }
            }
            #if DEBUG
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu("Debug") {
                        Button("Toggle Premium") {
                            purchaseManager.toggleDebugPremium()
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
                        
                        Text("Calls Made: \(purchaseManager.callsMade)")
                    }
                }
            }
            #endif
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button(action: { showAccountSheet = true }) {
                            Label("Account", systemImage: "person.circle")
                        }
                        
                        Button(action: { showCallHistory = true }) {
                            Label("Call History", systemImage: "clock.arrow.circlepath")
                        }
                        
                        Button(action: { showSettingsSheet = true }) {
                            Label("Settings", systemImage: "gear")
                        }
                        
                        if !purchaseManager.isSubscribed {
                            Button(action: { showSubscriptionAlert = true }) {
                                Label("Upgrade to Premium", systemImage: "star.fill")
                            }
                        }
                        
                        Button(action: { showHelpSheet = true }) {
                            Label("Help & Support", systemImage: "questionmark.circle")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive, action: {
                            authViewModel.logout()
                        }) {
                            Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                        
                        #if DEBUG
                        Divider()
                        
                        Button(action: {
                            purchaseManager.toggleDebugPremium()
                        }) {
                            Label("Toggle Premium", systemImage: "hammer")
                        }
                        
                        Button(action: {
                            UserDefaults.standard.removeObject(forKey: "callsMadeCount")
                        }) {
                            Label("Reset Call Count", systemImage: "arrow.counterclockwise")
                        }
                        #endif
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(.primary)
                    }
                }
            }
            // Add sheets for each menu item
            .sheet(isPresented: $showAccountSheet) {
                AccountView()
            }
            .sheet(isPresented: $showSettingsSheet) {
                SettingsView()
            }
            .sheet(isPresented: $showHelpSheet) {
                HelpSupportView()
            }
            .sheet(isPresented: $showCallHistory) {
                CallHistoryView()
            }
        }
    }
    
    private func makeImmediateCall() {
        guard !phoneNumber.isEmpty else {
            alertTitle = "Error"
            alertMessage = "Please enter a phone number."
            showAlert = true
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
        
        isUpdatingName = true
        
        CallService.shared.updateUserName(to: trimmedName) { result in
            DispatchQueue.main.async {
                self.isUpdatingName = false
                switch result {
                case .success(let message):
                    logger.debug("Successfully updated username: \(message)")
                    alertTitle = "Success"
                    alertMessage = message
                    UserDefaults.standard.set(trimmedName, forKey: "userName")
                    
                case .failure(let error):
                    logger.error("Failed to update username: \(error.localizedDescription)")
                    alertTitle = "Error"
                    alertMessage = "Failed to update name: \(error.localizedDescription)"
                }
                showAlert = true
            }
        }
    }
}




