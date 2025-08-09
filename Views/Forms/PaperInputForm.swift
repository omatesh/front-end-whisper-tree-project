import SwiftUI

struct PaperInputForm: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var inputText: String = ""
    @State private var selectedInputType: PaperInput.InputType = .abstract
    @State private var isLoading = false
    
    let onSubmit: (PaperInput) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Input Type")
                        .font(.headline)
                    
                    Picker("Input Type", selection: $selectedInputType) {
                        ForEach(PaperInput.InputType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Enter \(selectedInputType.displayName)")
                        .font(.headline)
                    
                    TextEditor(text: $inputText)
                        .frame(minHeight: 200)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                }
                
                Text(placeholderText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                Spacer()
                
                Button(action: submitInput) {
                    if isLoading {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Processing...")
                        }
                    } else {
                        Text("Generate Paper Network")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(canSubmit ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(!canSubmit || isLoading)
            }
            .padding()
            .navigationTitle("Paper Network Input")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private var canSubmit: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var placeholderText: String {
        switch selectedInputType {
        case .title:
            return "Enter the title of a research paper to find related work"
        case .abstract:
            return "Paste the abstract of a paper to discover similar research"
        case .keywords:
            return "Enter research keywords separated by commas"
        case .topic:
            return "Describe the research topic or area you want to explore"
        }
    }
    
    private func submitInput() {
        guard canSubmit else { return }
        
        isLoading = true
        
        let paperInput = PaperInput(
            text: inputText.trimmingCharacters(in: .whitespacesAndNewlines),
            inputType: selectedInputType
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            onSubmit(paperInput)
            isLoading = false
            presentationMode.wrappedValue.dismiss()
        }
    }
}