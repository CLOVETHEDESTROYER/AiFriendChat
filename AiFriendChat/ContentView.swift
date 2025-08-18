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
    @State private var showOnboarding = false
    @State private var isOnboardingComplete = false
    
    var body: some View {
        Group {
            if authViewModel.isLoggedIn {
                if isOnboardingComplete {
                    // Main app interface
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
                } else {
                    // Show onboarding
                    OnboardingView(isOnboardingComplete: $isOnboardingComplete)
                }
            } else {
                // Not logged in - show auth
                AuthView()
            }
        }
        .fullScreenCover(isPresented: $showAuthView) {
            AuthView()
        }
        .onChange(of: authViewModel.isLoggedIn) { _, isLoggedIn in
            if isLoggedIn {
                // Add small delay to ensure auth state is stable before checking onboarding
                // This prevents cancellation of onboarding API calls during rapid state changes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    checkOnboardingStatus()
                }
            }
        }
        .onChange(of: authViewModel.errorMessage) { oldValue, newValue in
            if newValue?.contains("unauthorized") ?? false {
                showAuthView = true
            }
        }
        .onAppear {
            // TEMPORARY: Clear onboarding status for testing
            UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
            UserDefaults.standard.removeObject(forKey: "userName")
            
            // Check auth status on app launch
            checkAuthStatus()
        }
    }
    
    private func checkAuthStatus() {
        // Check if user has valid token
        if let accessToken = KeychainManager.shared.getToken(forKey: "accessToken"),
           !accessToken.isEmpty {
            
            // Validate token with backend before setting isLoggedIn = true
            Task {
                do {
                    // Try a simple authenticated request to validate the token
                    let backendService = BackendService.shared
                    _ = try await backendService.checkCallPermission()
                    
                    await MainActor.run {
                        authViewModel.isLoggedIn = true
                        checkOnboardingStatus()
                    }
                } catch BackendError.unauthorized {
                    // Token is invalid, clear it and show auth
                    await MainActor.run {
                        KeychainManager.shared.deleteToken(forKey: "accessToken")
                        KeychainManager.shared.deleteToken(forKey: "refreshToken")
                        authViewModel.isLoggedIn = false
                    }
                } catch {
                    // Network or other error, assume logged in but handle gracefully
                    await MainActor.run {
                        authViewModel.isLoggedIn = true
                        checkOnboardingStatus()
                    }
                }
            }
        } else {
            authViewModel.isLoggedIn = false
        }
    }
    
    private func checkOnboardingStatus() {
        // Check if onboarding is complete
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        print(" Onboarding check - UserDefaults shows: \(hasCompletedOnboarding)")
        
        // FORCE ONBOARDING FOR NEW USERS - TEMPORARY FIX
        if !hasCompletedOnboarding {
            print(" New user detected, forcing onboarding...")
            isOnboardingComplete = false
            return
        }
        
        // If no onboarding status is saved, assume new user needs onboarding
        if !hasCompletedOnboarding {
            Task {
                // Try to check backend onboarding status
                do {
                    let backendService = BackendService.shared
                    let status = try await backendService.getOnboardingStatus()
                    await MainActor.run {
                        isOnboardingComplete = status.isComplete
                        if status.isComplete {
                            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                        }
                    }
                } catch {
                    // If backend check fails, assume new user needs onboarding
                    print("Could not check onboarding status: \(error)")
                    await MainActor.run {
                        isOnboardingComplete = false
                    }
                }
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
