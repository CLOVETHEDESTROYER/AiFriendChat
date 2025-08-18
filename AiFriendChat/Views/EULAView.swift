import SwiftUI

struct EULAView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("End User License Agreement")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom)
                    
                    Text("""
                    This app is licensed, not sold, to you. Your license to this App is subject to your prior acceptance of Apple's standard Licensed Application End User License Agreement ("Standard EULA").
                    
                    Key Terms:
                    
                    • Scope of License: You may use this app on any Apple-branded products that you own or control
                    • Consent to Use of Data: The app may collect and use technical data to facilitate software updates and support
                    • Termination: This license is effective until terminated by you or the licensor
                    • External Services: The app may enable access to third-party services and websites
                    • No Warranty: The app is provided "AS IS" and "AS AVAILABLE" without warranty
                    • Limitation of Liability: The licensor's liability is limited as provided in the Standard EULA
                    
                    For the complete End User License Agreement, please visit:
                    """)
                    .padding(.bottom)
                    
                    Link("Apple's Standard EULA", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                        .foregroundColor(.blue)
                        .underline()
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("EULA")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct EULAView_Previews: PreviewProvider {
    static var previews: some View {
        EULAView()
    }
} 