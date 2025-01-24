//
//  LoginView.swift
//  AiFriendChat
//
//  Created by Carlos Alvarez on 10/19/24.
//


// Views/LoginView.swift
import SwiftUI
import SwiftData

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
            VStack {
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Login") {
                    authViewModel.login(email: email, password: password)
                }
                if let errorMessage = authViewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            }
            .padding()
        }
    }
