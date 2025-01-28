//
//  ScheduleCallView.swift
//  AiFriendChat
//
//  Created by Carlos Alvarez on 10/19/24.
//

import SwiftUI
import SwiftData

struct ScheduleCallView: View {
    @StateObject private var viewModel: ScheduleCallViewModel
    @Environment(\.presentationMode) var presentationMode
    
    // Initialize with pre-filled phone number and scenario
    init(phoneNumber: String, scenario: String) {
        _viewModel = StateObject(wrappedValue: ScheduleCallViewModel(phoneNumber: phoneNumber, selectedScenario: scenario))
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Call Details Section
                Section(header: Text("Call Details")) {
                    TextField("Phone Number", text: $viewModel.phoneNumber)
                        .keyboardType(.phonePad)
                    
                    DatePicker("Scheduled Time", selection: $viewModel.scheduledTime, in: Date()...)
                    
                    Picker("Scenario", selection: $viewModel.selectedScenario) {
                        ForEach(viewModel.scenarios, id: \.self) { scenario in
                            Text(scenario.replacingOccurrences(of: "_", with: " ").capitalized)
                                .tag(scenario)
                        }
                    }
                }
                
                // Action Button Section
                Section {
                    Button(action: {
                        viewModel.scheduleCall()
                    }) {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Schedule Call")
                        }
                    }
                    .disabled(viewModel.isLoading || viewModel.phoneNumber.isEmpty)
                }
                
                // Error Section (if applicable)
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
        }
    }
}

// Update the preview provider
struct ScheduleCallView_Previews: PreviewProvider {
    static var previews: some View {
        ScheduleCallView(phoneNumber: "1234567890", scenario: "default")
    }
}
