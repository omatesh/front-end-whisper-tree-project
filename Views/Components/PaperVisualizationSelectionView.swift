import SwiftUI

struct PaperVisualizationSelectionView: View {
    let collections: [Collection]
    let onDismiss: () -> Void
    
    @State private var selectedCollection: Collection?
    @State private var papers: [Paper] = []
    @State private var isLoadingPapers = false
    @State private var showVisualization = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if collections.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Collections Found")
                            .font(.headline)
                        
                        Text("Create a collection with papers to visualize embeddings")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Close") {
                            onDismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Select a collection to visualize:")
                            .font(.headline)
                        
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(collections) { collection in
                                    CollectionCard(
                                        collection: collection,
                                        isSelected: selectedCollection?.id == collection.id,
                                        onSelect: {
                                            selectedCollection = collection
                                            loadPapers(for: collection)
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        if let selected = selectedCollection {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Selected: \(selected.title)")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    Spacer()
                                    
                                    if isLoadingPapers {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else {
                                        Text("\(papers.count) papers")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                if !errorMessage.isEmpty {
                                    Text(errorMessage)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                                
                                if papers.count >= 2 && !isLoadingPapers {
                                    Button("Visualize Papers") {
                                        showVisualization = true
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .frame(maxWidth: .infinity)
                                } else if papers.count == 1 {
                                    Text("Need at least 2 papers for visualization")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                } else if papers.count == 0 && !isLoadingPapers && !errorMessage.isEmpty {
                                    Text("This collection has no papers with abstracts")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                }
            }
            .padding()
            .navigationTitle("Paper Visualization")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(
                leading: Button("Cancel") {
                    onDismiss()
                }
            )
        }
        .fullScreenCover(isPresented: $showVisualization) {
            if let selected = selectedCollection, !papers.isEmpty {
                let paperData = papers.compactMap { paper -> (title: String, abstract: String)? in
                    guard let abstract = paper.abstract, !abstract.isEmpty else { return nil }
                    return (title: paper.title, abstract: abstract)
                }
                EmbeddingVisualizationView(
                    papers: paperData,
                    title: "\(selected.title) - Embeddings",
                    onDismiss: { showVisualization = false }
                )
            }
        }
    }
    
    private func loadPapers(for collection: Collection) {
        isLoadingPapers = true
        errorMessage = ""
        papers = []
        
        Task {
            do {
                let loadedPapers = try await APIService.shared.fetchPapers(for: collection.id)
                
                await MainActor.run {
                    // Filter papers that have abstracts
                    papers = loadedPapers.filter { paper in
                        guard let abstract = paper.abstract, !abstract.isEmpty else { return false }
                        return abstract.count > 50 // Minimum length for meaningful embedding
                    }
                    isLoadingPapers = false
                }
                
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to load papers: \(error.localizedDescription)"
                    isLoadingPapers = false
                }
            }
        }
    }
}

struct CollectionCard: View {
    let collection: Collection
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(collection.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(collection.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    HStack {
                        Text("by \(collection.owner)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(collection.papersCount) papers")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}