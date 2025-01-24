//
//  CallViewModel.swift
//  AiFriendChat
//
//  Created by Carlos Alvarez on 10/23/24.
//


import Foundation
import SwiftUICore

class CallViewModel: ObservableObject {
    @Published var isCallInProgress = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let baseURL: String = "https://voice.hyperlabsai.com" // Updated for production

    func initiateCall(phoneNumber: String, scenario: String) {
        clearMessages()
        performCall(phoneNumber: phoneNumber, scenario: scenario)
    }

    private func performCall(phoneNumber: String, scenario: String) {
        guard let encodedPhoneNumber = phoneNumber.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let encodedScenario = scenario.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "\(baseURL)/make-call/\(encodedPhoneNumber)/\(encodedScenario)") else {
            setErrorMessage("Invalid URL")
            return
        }

        isCallInProgress = true

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(KeychainManager.shared.getToken(forKey: "accessToken") ?? "")", forHTTPHeaderField: "Authorization")

        print("Initiating call to URL: \(url.absoluteString)")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isCallInProgress = false
                if let error = error {
                    self.setErrorMessage("Network error: \(error.localizedDescription)")
                } else if let httpResponse = response as? HTTPURLResponse {
                    print("Received response with status code: \(httpResponse.statusCode)")
                    switch httpResponse.statusCode {
                    case 200:
                        if let data = data, let responseString = String(data: data, encoding: .utf8) {
                            print("Server response: \(responseString)")
                            self.setSuccessMessage("Call initiated successfully")
                        }
                    case 401:
                        self.setErrorMessage("Unauthorized: Please log in again")
                    default:
                        self.setErrorMessage("Server error: Status code \(httpResponse.statusCode)")
                    }
                } else {
                    self.setErrorMessage("Unknown error occurred")
                }
            }
        }.resume()
    }

    private func setErrorMessage(_ message: String) {
        DispatchQueue.main.async {
            self.errorMessage = message
            self.successMessage = nil
        }
    }

    private func setSuccessMessage(_ message: String) {
        DispatchQueue.main.async {
            self.successMessage = message
            self.errorMessage = nil
        }
    }

    private func clearMessages() {
        DispatchQueue.main.async {
            self.errorMessage = nil
            self.successMessage = nil
        }
    }
}
