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
    @State private var showingScheduleView = false
    @State private var userName = ""
    @State private var isUpdatingName = false // Add this state variable

    
    // Notification state variables
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showAlert = false
    
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
    
    init(modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: HomeViewModel(modelContext: modelContext))
        _callViewModel = StateObject(wrappedValue: CallViewModel())
    }
    
    var body: some View {
        NavigationView {
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
                        
                        Button(action: {
                            scheduleCall()
                        }) {
                            HStack {
                                Image(systemName: "calendar.badge.plus")
                                Text("Schedule Call")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color("AccentColor"))
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .navigationTitle("Home")
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
        alertTitle = "Call Initiated"
        alertMessage = "Your call has been successfully initiated."
        showAlert = true
    }
    
    private func scheduleCall() {
        guard !phoneNumber.isEmpty else {
            alertTitle = "Error"
            alertMessage = "Please enter a phone number."
            showAlert = true
            return
        }
        
        showingScheduleView = true
        alertTitle = "Call Scheduled"
        alertMessage = "Your call has been successfully scheduled."
        showAlert = true
    }
    
    private func updateUserName() {
            logger.debug("Starting updateUserName function")
            
            // Trim whitespace and validate
            let trimmedName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedName.isEmpty else {
                logger.error("Attempted to update with empty username")
                alertTitle = "Error"
                alertMessage = "Name cannot be empty."
                showAlert = true
                return
            }

            logger.debug("Attempting to update username to: \(trimmedName)")
            
        // Show loading state
        isUpdatingName = true
        
        let loadingTitle = alertTitle
        alertTitle = "Updating..."
        showAlert = true
        
        CallService.shared.updateUserName(to: trimmedName) { result in
                    DispatchQueue.main.async {
                        self.isUpdatingName = false
                        
                        switch result {
                        case .success(let message):
                            logger.debug("Successfully updated username: \(message)")
                            alertTitle = "Success"
                            alertMessage = message
                            // Store the name locally
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
