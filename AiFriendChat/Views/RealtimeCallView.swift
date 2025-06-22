import SwiftUI

struct RealtimeCallView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var callViewModel: CallViewModel
    @Environment(\.dismiss) private var dismiss
    let scenario: String
    
    init(scenario: String) {
        self.scenario = scenario
        _callViewModel = StateObject(wrappedValue: CallViewModel(modelContext: modelContext))
    }
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [Color("Color"), Color("Color 2")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack {
                Text("Call Status: \(callViewModel.isCallInProgress ? "Connecting..." : "Disconnected")")
                    .foregroundColor(.white)
                    .padding()
                
                Button(action: { dismiss() }) {
                    Text("End Call")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(10)
                }
                .padding()
            }
        }
    }
}

struct RealtimeCallView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            RealtimeCallView(scenario: "default")
        }
    }
} 