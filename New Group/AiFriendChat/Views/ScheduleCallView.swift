//
//  ScheduleCallView.swift
//  AiFriendChat
//
//  Created by Carlos Alvarez on 10/19/24.
//


// Views/ScheduleCallView.swift
import SwiftUI
import SwiftData

struct ScheduleCallView: View {
    @StateObject private var viewModel: ScheduleCallViewModel
    @Environment(\.presentationMode) var presentationMode
    
    init(phoneNumber: Binding<String>, scenario: Binding<String>) {
        _viewModel = StateObject(wrappedValue: ScheduleCallViewModel(phoneNumber: phoneNumber.wrappedValue, selectedScenario: scenario.wrappedValue))
    }
    
    var body: some View {
        NavigationView {
            Form {
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
                    .disabled(viewModel.isLoading)
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Schedule Call")
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

struct AlertItem: Identifiable {
    let id = UUID()
    let message: String
}

// Update the preview provider
struct ScheduleCallView_Previews: PreviewProvider {
    @State static var previewPhoneNumber = "1234567890"
    @State static var previewScenario = "Basic Scenario"
    
    static var previews: some View {
        ScheduleCallView(phoneNumber: $previewPhoneNumber, scenario: $previewScenario)
    }
}
