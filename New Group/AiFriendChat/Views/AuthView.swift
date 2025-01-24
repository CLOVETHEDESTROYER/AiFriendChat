//
//  AuthView.swift
//  AiFriendChat
//
//  Created by Carlos Alvarez on 10/19/24.
//

import SwiftUI
import SwiftData

struct AuthView: View {
    @EnvironmentObject var viewModel: AuthViewModel
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
                    gradient: Gradient(colors: [Color("Color"), Color("AccentColor")]),
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
                    .foregroundColor(.black) // Black text for app name
                    .padding(.bottom, 20)
                
                // Login/Register Title
                Text(isLogin ? "Login" : "Register")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding()
                
                // Email Text Field
                TextField("Email", text: $email)
                    .padding()
                    .background(Color.white.opacity(0.8)) // Background for better contrast
                    .cornerRadius(15) // Rounded edges
                    .foregroundColor(.black) // Black text inside the text field
                    .autocapitalization(.none) // Disable capitalization
                    .textInputAutocapitalization(.never) // Disable auto-capitalization
                    .keyboardType(.emailAddress) // Use email keyboard
                    .padding(.horizontal, 30)
                
                // Password Text Field
                SecureField("Password", text: $password)
                    .padding()
                    .background(Color.white.opacity(0.8)) // Background for better contrast
                    .cornerRadius(15) // Rounded edges
                    .foregroundColor(.black) // Black text inside the secure field
                    .padding(.horizontal, 30)
                
                // Login/Register Button
                Button(action: {
                    if isLogin {
                        viewModel.login(email: email.trimmingCharacters(in: .whitespacesAndNewlines), password: password)
                    } else {
                        viewModel.register(email: email.trimmingCharacters(in: .whitespacesAndNewlines), password: password)
                    }
                }) {
                    Text(isLogin ? "Login" : "Register")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color("highlight")) // Button uses "highlight" color
                        .cornerRadius(10) // Rounded button
                        .padding(.horizontal, 30)
                }
                .padding()
                
                // Error Message
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                
                // Toggle Between Login and Register
                Button(isLogin ? "Need an account? Register" : "Already have an account? Login") {
                    isLogin.toggle()
                    viewModel.errorMessage = nil
                }
                .foregroundColor(.white)
                .padding()
            }
            .padding()
        }
    }
}

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView()
            .environmentObject(AuthViewModel())
    }
}
