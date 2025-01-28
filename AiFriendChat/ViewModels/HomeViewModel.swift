//
//  HomeViewModel.swift
//  AiFriendChat
//
//  Created by Carlos Alvarez on 10/19/24.
//

// ViewModels/HomeViewModel.swift
import Foundation
import SwiftData

@MainActor
class HomeViewModel: ObservableObject {
    @Published var scheduledCalls: [CallSchedule] = []
    @Published var userName: String = "" // Add a published property for the user's name
    
    private var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func fetchScheduledCalls() {
        do {
            let descriptor = FetchDescriptor<CallSchedule>(sortBy: [SortDescriptor(\.scheduledTime)])
            scheduledCalls = try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching scheduled calls: \(error)")
        }
    }
    
    // Function to update the user's name
    func updateUserName(to newName: String, completion: @escaping (Bool) -> Void) {
        guard !newName.isEmpty else {
            completion(false)
            return
        }
        
        CallService.shared.updateUserName(to: newName) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let message):
                    self.userName = newName
                    print("Update successful: \(message)")
                    completion(true)
                case .failure(let error):
                    print("Update failed: \(error.localizedDescription)")
                    completion(false)
                }
            }
        }
    }
}
