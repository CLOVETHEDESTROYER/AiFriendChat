import Foundation

class CallViewModel: ObservableObject {
    @Published var isCallInProgress = false
    private let baseURL = "http://your-backend-url.com" // Replace with your actual backend URL

    func initiateCall(phoneNumber: String, scenario: String) {
        guard let url = URL(string: "\(baseURL)/make-call/\(phoneNumber)/\(scenario)") else { return }
        
        isCallInProgress = true
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isCallInProgress = false
                // Handle response, show success or error message
            }
        }.resume()
    }
}