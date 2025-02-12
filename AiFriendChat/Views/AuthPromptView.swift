import SwiftUI

struct AuthPromptView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @Binding var showAuthView: Bool
    
    var body: some View {
        ZStack {
            Color("Color").edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 15) {
                    Image(systemName: "phone.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                    
                    Text("Ready to Start Calling?")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Sign up or log in to start making calls and accessing all features")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Action Buttons
                VStack(spacing: 15) {
                    Button(action: {
                        dismiss()
                        showAuthView = true
                    }) {
                        Text("Sign Up")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(15)
                    }
                    
                    Button(action: {
                        dismiss()
                        showAuthView = true
                    }) {
                        Text("Log In")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("highlight"))
                            .cornerRadius(15)
                    }
                    
                    Button(action: { dismiss() }) {
                        Text("Maybe Later")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 30)
            }
            .padding(.vertical, 40)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

struct AuthPromptView_Previews: PreviewProvider {
    static var previews: some View {
        AuthPromptView(showAuthView: .constant(false))
            .environmentObject(AuthViewModel())
    }
}
