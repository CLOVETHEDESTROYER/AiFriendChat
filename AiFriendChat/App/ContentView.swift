// App/ContentView.swift
struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        if authViewModel.isLoggedIn {
            HomeView()
        } else {
            TabView {
                LoginView()
                    .tabItem { Label("Login", systemImage: "person.fill") }
                RegisterView()
                    .tabItem { Label("Register", systemImage: "person.badge.plus") }
            }
        }
    }
}