import SwiftUI

struct RealtimeCallView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var callViewModel: CallViewModel?
    @Environment(\.dismiss) private var dismiss
    let scenario: String
    
    init(scenario: String) {
        self.scenario = scenario
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
                if let callViewModel = callViewModel {
                    Text("Call Status: \(callViewModel.isCallInProgress ? "Connecting..." : "Disconnected")")
                        .foregroundColor(.white)
                        .padding()
                } else {
                    Text("Initializing...")
                        .foregroundColor(.white)
                        .padding()
                }
                
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
        .onAppear {
            if callViewModel == nil {
                callViewModel = CallViewModel(modelContext: modelContext)
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