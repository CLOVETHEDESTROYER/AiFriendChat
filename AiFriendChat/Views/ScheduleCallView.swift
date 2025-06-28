//
//  ScheduleCallView.swift
//  AiFriendChat
//
//  Created by Carlos Alvarez on 10/19/24.
//

import SwiftUI
import SwiftData

struct ScheduleCallView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var viewModel: ScheduleCallViewModel
    @Environment(\.presentationMode) var presentationMode
    @Query private var savedPrompts: [SavedPrompt]
    @FocusState private var isInputActive: Bool
    
    init(phoneNumber: String, scenario: String) {
        let vm = ScheduleCallViewModel()
        vm.phoneNumber = phoneNumber
        vm.selectedScenario = scenario
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Call Details")) {
                    TextField("Phone Number", text: $viewModel.phoneNumber)
                        .focused($isInputActive)
                        .keyboardType(.phonePad)
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("Done") {
                                    isInputActive = false
                                }
                            }
                        }
                    
                    DatePicker("Scheduled Time", selection: $viewModel.selectedDate, in: Date()...)
                    
                    Picker("Scenario Type", selection: $viewModel.isCustomScenario) {
                        Text("Standard").tag(false)
                        Text("Custom").tag(true)
                    }
                    
                    if viewModel.isCustomScenario {
                        Picker("Custom Scenario", selection: $viewModel.selectedCustomPrompt) {
                            ForEach(savedPrompts) { prompt in
                                Text("\(prompt.name) (\(prompt.scenarioId ?? "No ID"))")
                                    .tag(Optional(prompt))
                            }
                        }
                    } else {
                        Picker("Scenario", selection: $viewModel.selectedScenario) {
                            ForEach(standardScenarios, id: \.self) { scenario in
                                Text(scenario.replacingOccurrences(of: "_", with: " ").capitalized)
                                    .tag(scenario)
                            }
                        }
                    }
                }
                
                Section {
                    Button {
                        viewModel.scheduleCall()
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Schedule Call")
                        }
                    }
                    .disabled(viewModel.isLoading || viewModel.phoneNumber.isEmpty || 
                            (viewModel.isCustomScenario && viewModel.selectedCustomPrompt == nil))
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Schedule Call")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Success", isPresented: $viewModel.showSuccessAlert) {
                Button("OK") {
                    presentationMode.wrappedValue.dismiss()
                }
            } message: {
                Text("Call has been scheduled successfully!")
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .sheet(isPresented: $viewModel.showAuthPrompt) {
                AuthPromptView(showAuthView: $viewModel.showAuthView)
            }
            .fullScreenCover(isPresented: $viewModel.showAuthView) {
                AuthView()
            }
            .background(
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isInputActive = false
                    }
            )
        }
        .onAppear {
            viewModel.authViewModel = authViewModel
        }
    }
    
    private var standardScenarios: [String] {
        ["default", "sister_emergency", "mother_emergency", "yacht_party", "instigator", "gameshow_host"]
    }
}

struct ScheduleCallView_Previews: PreviewProvider {
    static var previews: some View {
        ScheduleCallView(phoneNumber: "1234567890", scenario: "default")
    }
}
