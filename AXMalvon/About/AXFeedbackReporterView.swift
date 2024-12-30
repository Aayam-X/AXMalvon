//
//  AXFeedbackReporterView.swift
//  Malvon
//
//  Created by Ashwin Paudel on 2024-11-29.
//

import SwiftUI

struct AXFeedbackReporterView: View {
    @State private var title: String = ""
    @State private var message: String = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("Feedback Reporter")
                .font(.largeTitle)
                .fontWeight(.bold)

            TextField("Title", text: $title)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            Text("Message:")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            TextEditor(text: $message)
                .frame(height: 150)
                .border(Color.gray, width: 1)
                .padding(.horizontal)

            Button(action: submitFeedback) {
                Text("Submit")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .cornerRadius(8)
            }
            .padding(.horizontal)
        }
        .padding()
    }

    func submitFeedback() {
        let email = "ashwonixer123@gmail.com"
        let subject =
            title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            ?? ""
        let body =
            message.addingPercentEncoding(
                withAllowedCharacters: .urlQueryAllowed) ?? ""

        if let url = URL(
            string: "mailto:\(email)?subject=\(subject)&body=\(body)"),
            NSWorkspace.shared.open(url) {
            mxPrint("Mailto link opened successfully.")
        } else {
            mxPrint("Failed to open mailto link.")
        }
    }
}

#Preview {
    AXFeedbackReporterView()
}
