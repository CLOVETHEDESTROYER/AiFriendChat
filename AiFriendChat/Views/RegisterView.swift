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
        VStack {
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            Button("Register") {
                authViewModel.register(email: email, password: password)
            }
        }
        .padding()
    }
}
