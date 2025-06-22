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
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var showAuthView = false
    
    var body: some View {
        Group {
            TabView {
                CallView(modelContext: modelContext)
                    .tabItem {
                        Label("Call", systemImage: "phone.fill")
                    }
                
                ScheduleView()
                    .tabItem {
                        Label("Schedule", systemImage: "calendar")
                    }
                
                CallHistoryView()
                    .tabItem {
                        Label("History", systemImage: "clock.fill")
                    }
                
                SettingsTabView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
            }
            .tint(Color("highlight"))
        }
        .fullScreenCover(isPresented: $showAuthView) {
            AuthView()
        }
        .onChange(of: authViewModel.errorMessage) { oldValue, newValue in
            if newValue?.contains("unauthorized") ?? false {
                showAuthView = true
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthViewModel())
    }
}
