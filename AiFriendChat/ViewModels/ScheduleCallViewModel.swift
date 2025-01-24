// ViewModels/ScheduleCallViewModel.swift
class ScheduleCallViewModel: ObservableObject {
    @Published var phoneNumber = ""
    @Published var scheduledTime = Date()
    @Published var selectedScenario = "Work Emergency"
    
    func scheduleCall() {
        // Schedule call using CallService
    }
}