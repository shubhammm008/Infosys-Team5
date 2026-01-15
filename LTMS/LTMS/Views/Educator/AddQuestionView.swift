//
//  AddQuestionView.swift
//  LTMS
//
//  Created for Quiz Feature - Educator View
//

import SwiftUI

/// View for adding a new MCQ question to a quiz
struct AddQuestionView: View {
    let assessmentId: String
    let orderIndex: Int
    let onAdded: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var questionText = ""
    @State private var options: [String] = ["", "", "", ""]
    @State private var correctAnswerIndex = 0
    @State private var points: Int = 1
    
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private var isValid: Bool {
        !questionText.isEmpty &&
        options.filter { !$0.isEmpty }.count >= 2 &&
        !options[correctAnswerIndex].isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.dashboardBg.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom Header
                    HStack {
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundColor(.dashboardTextSecondary)
                        
                        Spacer()
                        
                        Text("Add Question")
                            .font(.headline)
                            .foregroundColor(.dashboardTextPrimary)
                        
                        Spacer()
                        
                        // Invisible spacer for balance
                        Button("Cancel") { }
                            .opacity(0)
                    }
                    .padding()
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            // Question Section
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Question")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.dashboardTextSecondary)
                                
                                customTextField(title: "Enter your question", text: $questionText, isMultiline: true)
                            }
                            .padding()
                            .background(Color.dashboardCard)
                            .cornerRadius(20)
                            
                            // Options Section
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("Answer Options")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.dashboardTextSecondary)
                                    
                                    Spacer()
                                    
                                    Text("Select correct answer")
                                        .font(.caption)
                                        .foregroundColor(.dashboardTextSecondary)
                                }
                                
                                VStack(spacing: 12) {
                                    ForEach(0..<options.count, id: \.self) { index in
                                        HStack(spacing: 12) {
                                            Button {
                                                correctAnswerIndex = index
                                            } label: {
                                                Image(systemName: correctAnswerIndex == index ? "checkmark.circle.fill" : "circle")
                                                    .font(.title3)
                                                    .foregroundColor(correctAnswerIndex == index ? .green : .dashboardTextSecondary)
                                            }
                                            .buttonStyle(.plain)
                                            
                                            TextField("Option \(index + 1)", text: $options[index])
                                                .padding(12)
                                                .background(Color.white.opacity(0.05))
                                                .cornerRadius(12)
                                                .foregroundColor(.dashboardTextPrimary)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(correctAnswerIndex == index ? Color.green.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
                                                )
                                        }
                                    }
                                }
                                
                                // Add Option Button
                                if options.count < 6 {
                                    Button {
                                        options.append("")
                                    } label: {
                                        HStack {
                                            Image(systemName: "plus.circle.fill")
                                            Text("Add Option")
                                        }
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.accentBlue)
                                        .padding(.top, 4)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.dashboardCard)
                            .cornerRadius(20)
                            
                            // Points Section
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Points")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.dashboardTextSecondary)
                                
                                customTextField(
                                    title: "Points value",
                                    text: Binding(
                                        get: { String(points) },
                                        set: { if let value = Int($0) { points = value } }
                                    )
                                )
                                .keyboardType(.numberPad)
                            }
                            .padding()
                            .background(Color.dashboardCard)
                            .cornerRadius(20)
                            
                            // Action Button
                            Button {
                                Task { await addQuestion() }
                            } label: {
                                ZStack {
                                    if isLoading {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Text("Add Question")
                                            .fontWeight(.bold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    LinearGradient(
                                        colors: [Color.accentBlue, Color.accentPurple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(16)
                                .shadow(color: Color.accentBlue.opacity(0.3), radius: 10, x: 0, y: 5)
                            }
                            .disabled(!isValid || isLoading)
                            .opacity((!isValid || isLoading) ? 0.6 : 1.0)
                        }
                        .padding()
                    }
                }
            }
            .navigationBarHidden(true)
            .alert("Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    @ViewBuilder
    private func customTextField(title: String, text: Binding<String>, isMultiline: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if !title.isEmpty {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.dashboardTextSecondary)
            }
            
            if isMultiline {
                TextEditor(text: text)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 100)
                    .padding(12)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                    .foregroundColor(.dashboardTextPrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            } else {
                TextField(title, text: text)
                    .padding(12)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                    .foregroundColor(.dashboardTextPrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            }
        }
    }
    
    private func addQuestion() async {
        // Filter out empty options
        let validOptions = options.filter { !$0.isEmpty }
        
        guard validOptions.count >= 2 else {
            errorMessage = "Please provide at least 2 options"
            showError = true
            return
        }
        
        guard correctAnswerIndex < options.count && !options[correctAnswerIndex].isEmpty else {
            errorMessage = "Please select a valid correct answer"
            showError = true
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let question = QuizQuestion.createMCQ(
            assessmentId: assessmentId,
            questionText: questionText,
            options: validOptions,
            correctAnswer: options[correctAnswerIndex],
            points: points,
            orderIndex: orderIndex
        )
        
        do {
            _ = try await QuizService.shared.createQuestion(question)
            onAdded()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - True/False Question View (bonus)

struct AddTrueFalseQuestionView: View {
    let assessmentId: String
    let orderIndex: Int
    let onAdded: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var questionText = ""
    @State private var correctAnswer = true
    @State private var points: Int = 1
    
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.dashboardBg.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom Header
                    HStack {
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundColor(.dashboardTextSecondary)
                        
                        Spacer()
                        
                        Text("True/False Question")
                            .font(.headline)
                            .foregroundColor(.dashboardTextPrimary)
                        
                        Spacer()
                        
                        Button("Cancel") { }
                            .opacity(0)
                    }
                    .padding()
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            // Statement Section
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Statement")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.dashboardTextSecondary)
                                
                                customTextField(title: "Enter the statement", text: $questionText, isMultiline: true)
                            }
                            .padding()
                            .background(Color.dashboardCard)
                            .cornerRadius(20)
                            
                            // Correct Answer Section
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Correct Answer")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.dashboardTextSecondary)
                                
                                HStack(spacing: 0) {
                                    Button {
                                        correctAnswer = true
                                    } label: {
                                        Text("True")
                                            .fontWeight(.semibold)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(correctAnswer ? Color.accentBlue : Color.white.opacity(0.05))
                                            .foregroundColor(correctAnswer ? .white : .dashboardTextSecondary)
                                    }
                                    
                                    Divider()
                                        .background(Color.white.opacity(0.1))
                                    
                                    Button {
                                        correctAnswer = false
                                    } label: {
                                        Text("False")
                                            .fontWeight(.semibold)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(!correctAnswer ? Color.accentBlue : Color.white.opacity(0.05))
                                            .foregroundColor(!correctAnswer ? .white : .dashboardTextSecondary)
                                    }
                                }
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                            }
                            .padding()
                            .background(Color.dashboardCard)
                            .cornerRadius(20)
                            
                            // Points Section
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Points")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.dashboardTextSecondary)
                                
                                customTextField(
                                    title: "Points value",
                                    text: Binding(
                                        get: { String(points) },
                                        set: { if let value = Int($0) { points = value } }
                                    )
                                )
                                .keyboardType(.numberPad)
                            }
                            .padding()
                            .background(Color.dashboardCard)
                            .cornerRadius(20)
                            
                            // Action Button
                            Button {
                                Task { await addQuestion() }
                            } label: {
                                ZStack {
                                    if isLoading {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Text("Add Question")
                                            .fontWeight(.bold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    LinearGradient(
                                        colors: [Color.accentBlue, Color.accentPurple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(16)
                                .shadow(color: Color.accentBlue.opacity(0.3), radius: 10, x: 0, y: 5)
                            }
                            .disabled(questionText.isEmpty || isLoading)
                            .opacity((questionText.isEmpty || isLoading) ? 0.6 : 1.0)
                        }
                        .padding()
                    }
                }
            }
            .navigationBarHidden(true)
            .alert("Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    @ViewBuilder
    private func customTextField(title: String, text: Binding<String>, isMultiline: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if !title.isEmpty {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.dashboardTextSecondary)
            }
            
            if isMultiline {
                TextEditor(text: text)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 100)
                    .padding(12)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                    .foregroundColor(.dashboardTextPrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            } else {
                TextField(title, text: text)
                    .padding(12)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                    .foregroundColor(.dashboardTextPrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            }
        }
    }
    
    private func addQuestion() async {
        isLoading = true
        defer { isLoading = false }
        
        let question = QuizQuestion.createTrueFalse(
            assessmentId: assessmentId,
            questionText: questionText,
            correctAnswer: correctAnswer,
            points: points,
            orderIndex: orderIndex
        )
        
        do {
            _ = try await QuizService.shared.createQuestion(question)
            onAdded()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

#Preview {
    AddQuestionView(assessmentId: "quiz123", orderIndex: 1) { }
}
