import SwiftUI
import SwiftData

struct CallHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CallHistory.timestamp, order: .reverse) private var callHistory: [CallHistory]
    @StateObject private var purchaseManager = PurchaseManager.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color("Color"), Color("Color 2")]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
                
                if !purchaseManager.isSubscribed {
                    PremiumPromptView()
                } else if callHistory.isEmpty {
                    EmptyHistoryView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(callHistory) { call in
                                CallHistoryCard(call: call)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Call History")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.fill")
                .font(.system(size: 60))
                .foregroundColor(.white)
            
            Text("No Call History")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Your call history will appear here")
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

private struct PremiumPromptView: View {
    @StateObject private var purchaseManager = PurchaseManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
            
            Text("Premium Feature")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Upgrade to premium to access your call history")
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            PremiumUpgradeButton(purchaseManager: purchaseManager, style: .primary)
            RestorePurchasesButton(purchaseManager: purchaseManager)
        }
        .padding()
    }
}

private struct CallHistoryCard: View {
    let call: CallHistory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "phone.fill")
                    .foregroundColor(Color("highlight"))
                
                Text(call.phoneNumber)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                StatusBadge(status: call.status)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(call.scenario.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(call.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
}

private struct StatusBadge: View {
    let status: CallStatus
    
    var body: some View {
        Text(status.rawValue)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.color.opacity(0.2))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(status.color.opacity(0.5), lineWidth: 1)
            )
    }
}

#Preview {
    CallHistoryView()
} 