// ViewModels/HomeViewModel.swift
class HomeViewModel: ObservableObject {
    @Published var scheduledCalls: [CallSchedule] = []
    
    func fetchScheduledCalls() {
        // Fetch scheduled calls from CallService
    }
}