//
//  EnhancedUsageStatsView.swift
//  AiFriendChat
//
//  Created by AI Assistant on 2025-01-16
//

import SwiftUI

struct EnhancedUsageStatsView: View {
    let stats: UsageStats
    @State private var showingPricing = false
    @State private var pricingInfo: PricingInfo?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                HStack {
                    Text("Usage Statistics")
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                    Button("💰 Pricing") {
                        loadPricing()
                    }
                    .buttonStyle(.bordered)
                }
                
                // Trial Status
                if stats.is_trial_active && !stats.is_subscribed {
                    TrialStatusCard(stats: stats)
                }
                
                // Subscription Status
                if stats.is_subscribed {
                    SubscriptionStatusCard(stats: stats)
                }
                
                // Call Counts
                CallCountsCard(stats: stats)
                
                // Duration Tracking
                if let weeklyDuration = stats.total_call_duration_this_week,
                   let monthlyDuration = stats.total_call_duration_this_month {
                    DurationTrackingCard(
                        weeklyDuration: weeklyDuration,
                        monthlyDuration: monthlyDuration
                    )
                }
                
                // Addon Calls
                if let addonCalls = stats.addon_calls_remaining, addonCalls > 0 {
                    AddonCallsCard(addonCalls: addonCalls, expiry: stats.addon_calls_expiry)
                }
                
                // Upgrade Prompt
                if stats.upgrade_recommended {
                    UpgradePromptCard()
                }
                
                // Cycle Information
                CycleInformationCard(stats: stats)
            }
            .padding()
        }
        .sheet(isPresented: $showingPricing) {
            if let pricingInfo = pricingInfo {
                PricingSheet(pricingInfo: pricingInfo)
            } else {
                ProgressView("Loading pricing...")
                    .presentationDetents([.medium])
            }
        }
    }
    
    private func loadPricing() {
        showingPricing = true
        
        Task {
            do {
                let pricing = try await BackendService.shared.getPricing()
                await MainActor.run {
                    self.pricingInfo = pricing
                }
            } catch {
                await MainActor.run {
                    self.showingPricing = false
                }
                print("Failed to load pricing: \(error)")
            }
        }
    }
}

// MARK: - Component Cards

struct TrialStatusCard: View {
    let stats: UsageStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("🆓 Trial Status")
                    .font(.headline)
                Spacer()
                Text("Active")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Calls Remaining")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(stats.trial_calls_remaining)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(stats.trial_calls_remaining > 0 ? .green : .red)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Calls Used")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(stats.trial_calls_used)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
            }
            
            ProgressView(value: Double(stats.trial_calls_used), total: Double(stats.trial_calls_used + stats.trial_calls_remaining))
                .progressViewStyle(LinearProgressViewStyle(tint: stats.trial_calls_remaining > 0 ? .green : .red))
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SubscriptionStatusCard: View {
    let stats: UsageStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("💎 Subscription")
                    .font(.headline)
                Spacer()
                Text(subscriptionDisplayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            HStack {
                if stats.subscription_tier == "mobile_basic" {
                    VStack(alignment: .leading) {
                        Text("Weekly Calls")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(max(0, 5 - stats.calls_made_this_week))/5")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                } else if stats.subscription_tier == "mobile_premium" {
                    VStack(alignment: .leading) {
                        Text("Monthly Calls")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(max(0, 30 - stats.calls_made_this_month))/30")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Total Made")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(stats.calls_made_total)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var subscriptionDisplayName: String {
        switch stats.subscription_tier {
        case "mobile_basic":
            return "Basic"
        case "mobile_premium":
            return "Premium"
        default:
            return "Active"
        }
    }
}

struct CallCountsCard: View {
    let stats: UsageStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📊 Call Statistics")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                StatItem(title: "Today", value: "\(stats.calls_made_today)", color: .blue)
                StatItem(title: "This Week", value: "\(stats.calls_made_this_week)", color: .green)
                StatItem(title: "This Month", value: "\(stats.calls_made_this_month)", color: .orange)
                StatItem(title: "Total", value: "\(stats.calls_made_total)", color: .purple)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct DurationTrackingCard: View {
    let weeklyDuration: Int
    let monthlyDuration: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("⏱️ Call Duration")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("This Week")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatDuration(weeklyDuration))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("This Month")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatDuration(monthlyDuration))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return "\(minutes)m \(remainingSeconds)s"
    }
}

struct AddonCallsCard: View {
    let addonCalls: Int
    let expiry: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("🎁 Addon Calls")
                    .font(.headline)
                Spacer()
                Text("\(addonCalls) remaining")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            if let expiry = expiry {
                Text("Expires: \(formatDate(expiry))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}

struct UpgradePromptCard: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("💡 Ready to Upgrade?")
                .font(.headline)
            Text("Get more calls and longer conversations with our subscription plans!")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("View Plans") {
                // TODO: Handle upgrade action
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange, lineWidth: 1)
        )
    }
}

struct CycleInformationCard: View {
    let stats: UsageStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📅 Billing Cycles")
                .font(.headline)
            
            if let weekStart = stats.week_start_date {
                HStack {
                    Text("Week resets:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formatDate(weekStart))
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
            
            if let monthStart = stats.month_start_date {
                HStack {
                    Text("Month resets:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formatDate(monthStart))
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .short
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}

struct PricingSheet: View {
    let pricingInfo: PricingInfo
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("💰 Pricing Plans")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    ForEach(pricingInfo.plans, id: \.id) { plan in
                        PricingPlanCard(plan: plan)
                    }
                    
                    AddonPlanCard(addon: pricingInfo.addon)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

struct PricingPlanCard: View {
    let plan: PricingPlan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(plan.name)
                    .font(.headline)
                Spacer()
                Text(plan.price)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            Text("\(plan.calls) • \(plan.duration_limit)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(plan.features, id: \.self) { feature in
                    HStack {
                        Text("✓")
                            .foregroundColor(.green)
                        Text(feature)
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct AddonPlanCard: View {
    let addon: AddonPlan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(addon.name)
                    .font(.headline)
                Spacer()
                Text(addon.price)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
            }
            
            Text("\(addon.calls) • Expires in \(addon.expires)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(addon.description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange, lineWidth: 1)
        )
    }
}

struct EnhancedUsageStatsView_Previews: PreviewProvider {
    static var previews: some View {
        let mockStats = UsageStats(
            app_type: "mobile_consumer",
            is_trial_active: true,
            trial_calls_remaining: 2,
            trial_calls_used: 1,
            calls_made_today: 1,
            calls_made_this_week: 3,
            calls_made_this_month: 8,
            calls_made_total: 15,
            is_subscribed: false,
            subscription_tier: nil,
            upgrade_recommended: true,
            total_call_duration_this_week: 180,
            total_call_duration_this_month: 450,
            addon_calls_remaining: 0,
            addon_calls_expiry: nil,
            week_start_date: "2024-01-15T10:30:00Z",
            month_start_date: "2024-01-15T10:30:00Z"
        )
        
        return EnhancedUsageStatsView(stats: mockStats)
    }
}
