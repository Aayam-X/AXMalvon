import SwiftUI

struct AXWelcomeView: View {
    var window: NSWindow? // Reference to hosting window

    @State private var purpose: String = ""
    @State private var timeLimit: String = ""
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""
    @State private var isLoading: Bool = false
    @State private var navigateToBrowser: Bool = false
    @State private var wordCount: Int = 0
    @State private var isApproved: Bool = false
    
    private let maxWords = 25
    private let minTimeLimit = 5
    private let maxTimeLimit = 180
    
    var body: some View {
            ScrollView {
                VStack(spacing: 35) {
                    // Header Section
                    VStack(spacing: 12) {
                        Image(systemName: "safari.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                            .symbolEffect(.pulse, options: .repeating)
                        
                        Text("Welcome to Malvon")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text("Your mindful browsing companion")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Main Form Section
                    VStack(spacing: 25) {
                        // Purpose Section
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Label("Purpose of browsing", systemImage: "target")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("\(wordCount)/\(maxWords)")
                                    .font(.subheadline)
                                    .foregroundColor(wordCount > maxWords ? .red : .secondary)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule()
                                            .fill(wordCount > maxWords ? Color.red.opacity(0.1) : Color.gray.opacity(0.1))
                                    )
                            }
                            
                            ZStack(alignment: .topLeading) {
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.gray.opacity(0.08))
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    .frame(height: 100)
                                
                                TextEditor(text: $purpose)
                                    .padding(12)
                                    .background(Color.clear)
                                    .font(.body)
                                    .scrollContentBackground(.hidden)
                                    .onChange(of: purpose) { _ in
                                        limitWords()
                                        updateWordCount()
                                    }
                                
                                if purpose.isEmpty {
                                    Text("e.g., Research renewable energy solutions for my environmental science project")
                                        .foregroundColor(.secondary)
                                        .font(.body)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 20)
                                        .allowsHitTesting(false)
                                }
                            }
                            
                            if wordCount > maxWords {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                    Text("Please keep your purpose under \(maxWords) words")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        
                        // Time Limit Section
                        VStack(alignment: .leading, spacing: 15) {
                            Label("Time limit (minutes)", systemImage: "clock.fill")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            HStack(spacing: 15) {
                                TextField("30", text: $timeLimit)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 100)
                                    .font(.title3)
                                    .multilineTextAlignment(.center)
                                
                                Text("minutes")
                                    .foregroundColor(.secondary)
                                    .font(.title3)
                                
                                Spacer()
                            }
                            
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                Text("Recommended: \(minTimeLimit)-\(maxTimeLimit) minutes for optimal focus")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    
                    // Action Button Section
                    VStack(spacing: 20) {
                        if isLoading {
                            VStack(spacing: 12) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(1.3)
                                Text("Evaluating your purpose...")
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                            }
                            .frame(height: 80)
                        } else {
                            Button(action: {
                                Task {
                                    await evaluatePurpose()
                                }
                            }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title2)
                                    Text("Start Focused Browsing")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.blue, Color.blue.opacity(0.8)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                                )
                                .foregroundColor(.white)
                            }
                            .buttonStyle(.plain)
                            .disabled(purpose.isEmpty || timeLimit.isEmpty || wordCount > maxWords)
                            .opacity(purpose.isEmpty || timeLimit.isEmpty || wordCount > maxWords ? 0.6 : 1.0)
                            .scaleEffect(purpose.isEmpty || timeLimit.isEmpty || wordCount > maxWords ? 0.98 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: purpose.isEmpty || timeLimit.isEmpty || wordCount > maxWords)
                        }
                        
                        // Tips Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(.orange)
                                Text("Tips for focused browsing")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                tipRow("Be specific about your research goal", icon: "target")
                                tipRow("Set realistic time limits for your task", icon: "clock")
                                tipRow("Take breaks every 30-45 minutes", icon: "figure.walk")
                                tipRow("Avoid social media during focus time", icon: "phone.badge.waveform")
                            }
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.orange.opacity(0.08), Color.yellow.opacity(0.05)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                        )
                    }
                }
                .padding(30)
            }
            .alert(alertTitle, isPresented: $showAlert) {
                if isApproved {
                    Button("Continue Browsing") {
                        AXSharedTimer.shared.setTimerValue(Int(timeLimit) ?? 5)
                        self.window?.close()

                        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
                            let _ = appDelegate.presentNewWindowIfNeeded()
                        }
                    }
                    .keyboardShortcut(.return)
                    
                    Button("Revise Purpose") {
                        // User can edit their purpose
                    }
                } else {
                    Button("Try Again") {
                        // User can modify and resubmit
                    }
                    .keyboardShortcut(.return)
                }
            } message: {
                Text(alertMessage)
            }
        .frame(minWidth: 600, minHeight: 700)
    }
    
    private func tipRow(_ text: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.orange)
                .frame(width: 16)
            Text(text)
            Spacer()
        }
    }
    
    private func limitWords() {
        let words = purpose.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        if words.count > maxWords {
            let limitedWords = Array(words.prefix(maxWords))
            purpose = limitedWords.joined(separator: " ")
        }
    }
    
    private func updateWordCount() {
        let words = purpose.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        wordCount = words.count
    }
    
    private func evaluatePurpose() async {
        guard !purpose.isEmpty else {
            showError("Please enter your purpose for browsing.")
            return
        }
        
        guard let timeLimitInt = Int(timeLimit), timeLimitInt >= minTimeLimit, timeLimitInt <= maxTimeLimit else {
            showError("Please enter a time limit between \(minTimeLimit) and \(maxTimeLimit) minutes.")
            return
        }
        
        guard wordCount <= maxWords else {
            showError("Please keep your purpose under \(maxWords) words.")
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let prompt = """
        Evaluate the following browsing purpose for productivity and focus: "\(purpose)"
        
        Rules for evaluation:
        - APPROVE only if the purpose is specific, goal-oriented, and clearly related to learning, research, work, or meaningful personal development.
        - DO NOT APPROVE if the purpose is vague, entertainment-oriented, or primarily for leisure (examples: watching anime, Netflix, TikTok, YouTube, gaming, social media scrolling, streaming shows, movies, etc.).
        - If the purpose mixes both productivity and entertainment, lean toward NOT APPROVED unless the productivity aspect is dominant and explicit.
        - Keep your feedback short, clear, and actionable.
        
        Respond in exactly one of these formats:
        APPROVED: [brief encouraging reason]
        NOT APPROVED: [brief constructive feedback]
        """
        
        do {
            if let result = try await callGeminiAPI(prompt: prompt) {
                if result.uppercased().starts(with: "APPROVED") {
                    isApproved = true
                    alertTitle = "Purpose Approved! 🎯"
                    alertMessage = result.replacingOccurrences(of: "APPROVED:", with: "").trimmingCharacters(in: .whitespaces)
                } else if result.uppercased().starts(with: "NOT APPROVED") {
                    isApproved = false
                    alertTitle = "Let's Refine Your Purpose"
                    alertMessage = result.replacingOccurrences(of: "NOT APPROVED:", with: "").trimmingCharacters(in: .whitespaces)
                } else {
                    // Fallback if Gemini responds with something unexpected
                    isApproved = false
                    alertTitle = "Oops!"
                    alertMessage = "Unexpected response: \(result)"
                }
                showAlert = true
            } else {
                showError("Unable to evaluate purpose. Please try again.")
            }
        } catch {
            showError("Network error. Please check your connection and try again.")
            print("Gemini API Error: \(error)")
        }
    }
    
    private func showError(_ message: String) {
        alertTitle = "Oops!"
        alertMessage = message
        isApproved = false
        showAlert = true
    }
    
    // MARK: - Google Gemini 2.0 Flash API Call
    private func callGeminiAPI(prompt: String) async throws -> String? {
        // Replace with your Google AI Studio API key
        let apiKey = "AIzaSyDn4OSCfCa1hisr5MEjKBpYQCG2URMcEqU"
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(apiKey, forHTTPHeaderField: "X-goog-api-key")
        
        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.2,
                "maxOutputTokens": 150,
                "topP": 0.8,
                "topK": 20
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check for HTTP errors
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode != 200 {
                print("HTTP Error: \(httpResponse.statusCode)")
                if let errorData = String(data: data, encoding: .utf8) {
                    print("Error response: \(errorData)")
                }
                return nil
            }
        }
        
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let candidates = json["candidates"] as? [[String: Any]],
           let firstCandidate = candidates.first,
           let content = firstCandidate["content"] as? [String: Any],
           let parts = content["parts"] as? [[String: Any]],
           let firstPart = parts.first,
           let text = firstPart["text"] as? String {
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return nil
    }
}

#Preview {
    AXWelcomeView()
}
