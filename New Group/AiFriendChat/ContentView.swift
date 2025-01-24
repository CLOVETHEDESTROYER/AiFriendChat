//
//  ContentView.swift
//  AiFriendChat
//
//  Created by Carlos Alvarez on 10/19/24.
//


// App/ContentView.swift
import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        if authViewModel.isLoggedIn {
            HomeView(modelContext: modelContext)
                .environmentObject(authViewModel)
        } else {
            AuthView()
                .environmentObject(authViewModel)
        }
    }
}
