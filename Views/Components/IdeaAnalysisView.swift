import SwiftUI

struct IdeaAnalysisView: View {
    @State private var showVisualization = false
    @State private var visualizationData: VisualizationResponse?
    @State private var isLoading = false
    @State private var inputText: String = ""
    @State private var selectedCollection: Collection?
    @State private var availableCollections: [Collection] = []
    @State private var isLoadingCollections: Bool = false
    @State private var errorMessage: String = ""
    
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        
                        Text("Generating Idea Analysis...")
                            .font(.headline)
                        
                        Text("Analyzing your input and finding related papers")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Show input form content directly
                    VStack(spacing: 20) {
                        // Collection Selection Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Target Collection")
                                .font(.headline)
                            
                            if isLoadingCollections {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Loading collections...")
                                        .foregroundColor(.secondary)
                                }
                            } else if availableCollections.isEmpty {
                                Text("No collections available")
                                    .foregroundColor(.secondary)
                                    .italic()
                            } else {
                                Picker("Target Collection", selection: Binding(
                                    get: { selectedCollection?.id ?? -1 },
                                    set: { newId in
                                        if let collection = availableCollections.first(where: { $0.id == newId }) {
                                            selectedCollection = collection
                                        }
                                    }
                                )) {
                                    Text("Select a collection...")
                                        .tag(-1)
                                    
                                    ForEach(availableCollections) { collection in
                                        VStack(alignment: .leading) {
                                            Text(collection.title)
                                                .font(.headline)
                                            Text("\(collection.papersCount) papers")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        .tag(collection.id)
                                    }
                                }
                                .pickerStyle(.menu)
                                
                                // Show selected collection details
                                if let selected = selectedCollection {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(selected.title)
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                            Spacer()
                                            Text("\(selected.papersCount) papers")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        if !selected.description.isEmpty {
                                            Text(selected.description)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .lineLimit(2)
                                        }
                                        
                                        Text("Owner: \(selected.owner ?? "Unknown")")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background(Color.blue.opacity(0.05))
                                    .cornerRadius(6)
                                }
                            }
                            
                            if selectedCollection == nil {
                                Text("Please select a collection to analyze your idea against")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                            
                            if !errorMessage.isEmpty {
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Enter Your Idea")
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
                        
                        Text("Paste your idea of a paper to discover similar research")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        Spacer()
                        
                        Button(action: submitInput) {
                            Text("Analyze Idea")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canSubmit ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .disabled(!canSubmit || isLoading)
                    }
                    .padding()
                }
            }
            .navigationTitle("Idea Analysis")
            .navigationBarItems(
                leading: Button("Close") { onDismiss() }
            )
            .onAppear {
                loadAvailableCollections()
            }
        }
        .fullScreenCover(isPresented: $showVisualization) {
            if let visualizationData = visualizationData {
                CollectionVisualizationView(
                    visualization: visualizationData,
                    title: "Idea Analysis",
                    selectedCollection: selectedCollection,
                    onDismiss: { showVisualization = false }
                )
            }
        }
    }
    
    private var canSubmit: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && selectedCollection != nil
    }
    
    private func submitInput() {
        guard canSubmit, let collection = selectedCollection else { return }
        
        isLoading = true
        errorMessage = ""
        
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        Task {
            do {
                // Call new analyze idea API with collection ID
                let visualization = try await APIService.shared.analyzeIdea(
                    collectionId: collection.id,
                    userIdea: text
                )
                
                // Navigate to visualization view
                await MainActor.run {
                    isLoading = false
                    visualizationData = visualization
                    showVisualization = true
                }
                
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to analyze idea: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Load Collections
    private func loadAvailableCollections() {
        isLoadingCollections = true
        errorMessage = ""
        
        Task {
            do {
                let collections = try await APIService.shared.loadCollections()
                
                await MainActor.run {
                    availableCollections = collections
                    isLoadingCollections = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to load collections: \(error.localizedDescription)"
                    isLoadingCollections = false
                }
            }
        }
    }
}
