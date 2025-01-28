import SwiftUI
import MessageUI

struct HelpSupportView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showEmailSheet = false
    @State private var showReportIssue = false
    @State private var selectedFAQ: FAQ?
    
    // FAQ items
    enum FAQ: String, CaseIterable, Identifiable {
        case howItWorks = "How It Works"
        case billing = "Billing & Subscription"
        case technical = "Technical Support"
        case privacy = "Privacy & Security"
        
        var id: String { rawValue }
        
        var content: String {
            switch self {
            case .howItWorks:
                return """
                AI Friend Chat allows you to:
                1. Make immediate calls with AI
                2. Schedule calls for later
                3. Choose different conversation scenarios
                4. Customize your experience
                
                Premium features include unlimited calls and scheduling capabilities.
                """
            case .billing:
                return """
                Subscription Information:
                • Free trial includes 2 calls
                • Premium subscription unlocks unlimited calls
                • Monthly billing with auto-renewal
                • Cancel anytime through App Store
                
                For billing issues, please contact App Store support.
                """
            case .technical:
                return """
                Common Solutions:
                • Ensure you're logged in
                • Check your internet connection
                • Verify your phone number format
                • Update to the latest app version
                • Clear app cache if experiencing issues
                
                Still having problems? Contact our support team.
                """
            case .privacy:
                return """
                We take your privacy seriously:
                • All calls are encrypted
                • Data is stored securely
                • We never share your information
                • You can delete your data anytime
                
                Read our privacy policy for more details.
                """
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                Section("Frequently Asked Questions") {
                    ForEach(FAQ.allCases) { faq in
                        NavigationLink(destination: FAQDetailView(faq: faq)) {
                            Label(faq.rawValue, systemImage: faqIcon(for: faq))
                        }
                    }
                }
                
                Section("Contact Support") {
                    Button(action: { showEmailSheet = true }) {
                        Label("Email Support", systemImage: "envelope")
                    }
                    
                    Button(action: { showReportIssue = true }) {
                        Label("Report an Issue", systemImage: "exclamationmark.triangle")
                    }
                }
                
                Section("App Information") {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundColor(.gray)
                    }
                    
                    if let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                        HStack {
                            Label("Build", systemImage: "hammer")
                            Spacer()
                            Text(buildNumber)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .navigationTitle("Help & Support")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
            .sheet(isPresented: $showEmailSheet) {
                EmailView(toAddress: "support@aifriendchat.com")
            }
            .sheet(isPresented: $showReportIssue) {
                ReportIssueView()
            }
        }
    }
    
    private func faqIcon(for faq: FAQ) -> String {
        switch faq {
        case .howItWorks: return "questionmark.circle"
        case .billing: return "creditcard"
        case .technical: return "wrench.and.screwdriver"
        case .privacy: return "lock.shield"
        }
    }
}

struct FAQDetailView: View {
    let faq: HelpSupportView.FAQ
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(faq.content)
                    .padding()
            }
        }
        .navigationTitle(faq.rawValue)
    }
}

struct EmailView: View {
    let toAddress: String
    @Environment(\.dismiss) var dismiss
    @State private var subject = ""
    @State private var messageBody = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Email Support")) {
                    TextField("Subject", text: $subject)
                    TextEditor(text: $messageBody)
                        .frame(height: 200)
                }
                
                Button("Send Email") {
                    sendEmail()
                }
                .disabled(subject.isEmpty || messageBody.isEmpty)
            }
            .navigationTitle("Contact Support")
            .navigationBarItems(trailing: Button("Cancel") { dismiss() })
        }
    }
    
    private func sendEmail() {
        if MFMailComposeViewController.canSendMail() {
            let emailContent = """
            Subject: \(subject)
            
            \(messageBody)
            
            App Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
            Build: \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown")
            """
            
            // Implement email sending logic
            print(emailContent)
        }
        dismiss()
    }
}

struct ReportIssueView: View {
    @Environment(\.dismiss) var dismiss
    @State private var issueType = "Bug"
    @State private var description = ""
    @State private var includeDebugInfo = true
    
    let issueTypes = ["Bug", "Feature Request", "Performance", "Other"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Issue Details")) {
                    Picker("Type", selection: $issueType) {
                        ForEach(issueTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    
                    TextEditor(text: $description)
                        .frame(height: 150)
                        .overlay(
                            Group {
                                if description.isEmpty {
                                    Text("Describe the issue...")
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 8)
                                }
                            },
                            alignment: .topLeading
                        )
                }
                
                Section {
                    Toggle("Include Debug Information", isOn: $includeDebugInfo)
                }
                
                Button("Submit Report") {
                    submitReport()
                }
                .disabled(description.isEmpty)
            }
            .navigationTitle("Report Issue")
            .navigationBarItems(trailing: Button("Cancel") { dismiss() })
        }
    }
    
    private func submitReport() {
        // Implement report submission logic
        let report = """
        Type: \(issueType)
        Description: \(description)
        Include Debug Info: \(includeDebugInfo)
        """
        print(report)
        dismiss()
    }
} 