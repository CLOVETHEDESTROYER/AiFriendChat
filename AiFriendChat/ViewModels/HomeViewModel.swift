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
    @Published var userName: String = ""
    @Published var updateError: String?
    
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
    
    func updateUserName(to newName: String) async throws -> String {
        guard !newName.isEmpty else {
            throw NSError(domain: "", code: -1, 
                         userInfo: [NSLocalizedDescriptionKey: "Name cannot be empty"])
        }
        
        let message = try await CallService.shared.updateUserName(to: newName)
        userName = newName
        return message
    }
}
