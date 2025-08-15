import SwiftUI
import SwiftData

struct CallHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var callHistory: [CallHistory]
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
                    ScrollView(showsIndicators: true) {
                        LazyVStack(spacing: 15) {
                            ForEach(callHistory.sorted(by: { $0.timestamp > $1.timestamp })) { call in
                                CallHistoryCard(call: call)
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(formatPhoneNumber(call.phoneNumber))
                    .font(.headline)
                Spacer()
                Text(formatDate(call.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("Scenario: \(call.scenario)")
                .font(.subheadline)
            
            if call.duration > 0 {
                Text("Duration: \(formatDuration(call.duration))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Spacer()
                StatusBadge(status: call.status)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
    
    private func formatPhoneNumber(_ number: String) -> String {
        let cleaned = number.filter { $0.isNumber }
        guard cleaned.count == 10 else { return number }
        
        let area = cleaned.prefix(3)
        let prefix = cleaned.dropFirst(3).prefix(3)
        let number = cleaned.dropFirst(6)
        
        return "(\(area)) \(prefix)-\(number)"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}

private struct StatusBadge: View {
    let status: CallStatus
    
    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .cornerRadius(8)
    }
    
    private var statusColor: Color {
        switch status {
        case .completed:
            return .green
        case .failed:
            return .red
        case .cancelled:
            return .orange
        }
    }
}

#Preview {
    CallHistoryView()
} 
