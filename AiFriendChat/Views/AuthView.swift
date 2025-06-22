//
//  AuthView.swift
//  AiFriendChat
//
//  Created by Carlos Alvarez on 10/19/24.
//

import SwiftUI
import SwiftData

struct AuthView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isLogin = true
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        ZStack {
            // Background with main color and gradient
            VStack(spacing: 0) {
                // First 1/4 of the screen with the "AccentColor"
                Color("Color")
                    .frame(height: UIScreen.main.bounds.height / 4)
                
                // Remaining 3/4 of the screen with a gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color("Color"), Color("Color 2")]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: UIScreen.main.bounds.height * 3 / 4)
            }
            .edgesIgnoringSafeArea(.all)
            
            // Login form and other content
            VStack {
                // Logo
                Image("logo") // Replace with the name of your image in Assets
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300) // Adjust the size as needed
                    .padding()
                
                // App name
                Text("AI FRIEND CHAT")
                    .font(.system(size: 42, weight: .heavy, design: .rounded)) // Larger font size and boldness
                    .foregroundColor(.white) // Black text for app name
                    .padding(.bottom, 20)
                
                // Login/Register Title
                Text(isLogin ? "Login" : "Register")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding()
                
                // Email Text Field
                TextField("Email", text: $email)
                    .padding()
                    .background(Color.white.opacity(0.4)) // Background for better contrast
                    .cornerRadius(15) // Rounded edges
                    .foregroundColor(.black) // Black text inside the text field
                    .autocapitalization(.none) // Disable capitalization
                    .textInputAutocapitalization(.never) // Disable auto-capitalization
                    .keyboardType(.emailAddress) // Use email keyboard
                    .padding(.horizontal, 30)
                
                // Password Text Field
                SecureField("Password", text: $password)
                    .padding()
                    .background(Color.white.opacity(0.4)) // Background for better contrast
                    .cornerRadius(15) // Rounded edges
                    .foregroundColor(.black) // Black text inside the secure field
                    .padding(.horizontal, 30)
                
                // Login/Register Button
                Button(action: {
                    let lowercaseEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                    if isLogin {
                        authViewModel.login(email: lowercaseEmail, password: password)
                    } else {
                        authViewModel.register(email: lowercaseEmail, password: password)
                    }
                }) {
                    Text(isLogin ? "Login" : "Register")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color("highlight"))
                        .cornerRadius(10)
                        .padding(.horizontal, 30)
                }
                .padding()
                
                // Error Message
                if let errorMessage = authViewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                
                // Toggle Between Login and Register
                Button(isLogin ? "Need an account? Register" : "Already have an account? Login") {
                    isLogin.toggle()
                    authViewModel.errorMessage = nil
                }
                .foregroundColor(.white)
                .padding()
            }
            .padding()
        }
        .onChange(of: authViewModel.isLoggedIn) { oldValue, newValue in
            if newValue {
                dismiss()
            }
        }
    }
}

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView()
            .environmentObject(AuthViewModel())
    }
}
