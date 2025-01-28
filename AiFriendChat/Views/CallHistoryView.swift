import SwiftUI

struct CallHistoryView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var purchaseManager = PurchaseManager.shared
    @State private var selectedTimeFrame = TimeFrame.week
    @State private var showClearConfirmation = false
    
    enum TimeFrame: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case all = "All Time"
    }
    
    // Mock data - replace with actual data from your backend
    let callHistory = [
        CallRecord(id: UUID(), phoneNumber: "+1234567890", scenario: "default", date: Date().addingTimeInterval(-86400), duration: 120),
        CallRecord(id: UUID(), phoneNumber: "+1987654321", scenario: "sister_emergency", date: Date().addingTimeInterval(-172800), duration: 180),
        // Add more mock data as needed
    ]
    
    var filteredCalls: [CallRecord] {
        let calendar = Calendar.current
        let now = Date()
        
        return callHistory.filter { record in
            switch selectedTimeFrame {
            case .week:
                return calendar.isDate(record.date, equalTo: now, toGranularity: .weekOfYear)
            case .month:
                return calendar.isDate(record.date, equalTo: now, toGranularity: .month)
            case .all:
                return true
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                if purchaseManager.isSubscribed {
                    Section {
                        Picker("Time Frame", selection: $selectedTimeFrame) {
                            ForEach(TimeFrame.allCases, id: \.self) { timeFrame in
                                Text(timeFrame.rawValue).tag(timeFrame)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.vertical, 8)
                    }
                    
                    Section {
                        CallStatisticsView(calls: filteredCalls)
                    }
                    
                    Section("Call History") {
                        if filteredCalls.isEmpty {
                            Text("No calls in this time frame")
                                .foregroundColor(.gray)
                        } else {
                            ForEach(filteredCalls) { record in
                                CallHistoryRow(record: record)
                            }
                        }
                    }
                    
                    Section {
                        Button("Clear History", role: .destructive) {
                            showClearConfirmation = true
                        }
                    }
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.yellow)
                        
                        Text("Premium Feature")
                            .font(.title2)
                            .bold()
                        
                        Text("Upgrade to Premium to access your call history and statistics.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                        
                        Button(action: {
                            // Show subscription options
                        }) {
                            Text("Upgrade Now")
                                .bold()
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.yellow)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                }
            }
            .navigationTitle("Call History")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
            .alert("Clear History", isPresented: $showClearConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    // Implement clear history logic
                }
            } message: {
                Text("Are you sure you want to clear your call history? This action cannot be undone.")
            }
        }
    }
}

struct CallRecord: Identifiable {
    let id: UUID
    let phoneNumber: String
    let scenario: String
    let date: Date
    let duration: TimeInterval
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct CallHistoryRow: View {
    let record: CallRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(record.phoneNumber)
                    .font(.headline)
                Spacer()
                Text(record.formattedDuration)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            HStack {
                Text(record.scenario.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Spacer()
                Text(record.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
}

struct CallStatisticsView: View {
    let calls: [CallRecord]
    
    var totalDuration: TimeInterval {
        calls.reduce(0) { $0 + $1.duration }
    }
    
    var averageDuration: TimeInterval {
        calls.isEmpty ? 0 : totalDuration / Double(calls.count)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                StatisticCard(title: "Total Calls", value: "\(calls.count)")
                StatisticCard(title: "Total Duration", value: formatDuration(totalDuration))
            }
            
            HStack(spacing: 20) {
                StatisticCard(title: "Avg. Duration", value: formatDuration(averageDuration))
                StatisticCard(title: "Most Used Scenario", value: mostUsedScenario)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var mostUsedScenario: String {
        let scenarios = calls.map { $0.scenario }
        let counts = Dictionary(grouping: scenarios, by: { $0 }).mapValues { $0.count }
        return counts.max(by: { $0.value < $1.value })?.key.replacingOccurrences(of: "_", with: " ").capitalized ?? "N/A"
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        return "\(minutes) min"
    }
}

struct StatisticCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

#Preview {
    CallHistoryView()
} 