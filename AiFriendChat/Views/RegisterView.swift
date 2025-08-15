//
//  RegisterView.swift
//  AiFriendChat
//
//  Created by Carlos Alvarez on 10/19/24.
//


// Views/RegisterView.swift
import SwiftUI
import SwiftData

struct RegisterView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("Email", text: $email)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .keyboardType(.emailAddress)
                .padding()
                .background(Color(.systemBackground))
                .foregroundColor(Color(.label))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
            
            SecureField("Password", text: $password)
                .disableAutocorrection(true)
                .padding()
                .background(Color(.systemBackground))
                .foregroundColor(Color(.label))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
            
            Button("Register") {
                authViewModel.register(email: email, password: password)
            }
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .cornerRadius(12)
        }
        .padding()
    }
}
