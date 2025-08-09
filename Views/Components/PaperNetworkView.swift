import SwiftUI

struct PaperNetworkView: View {
    @State private var network: PaperNetwork?
    @State private var displayedNetwork: PaperNetwork?
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showInputForm = false
    @State private var showFilters = false
    @State private var showVisualization = false
    @State private var visualizationData: VisualizationResponse?
    @State private var filters = NetworkFilters()
    
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                if let displayedNetwork = displayedNetwork {
                    NetworkGraphView(network: displayedNetwork) { updatedNetwork in
                        network = updatedNetwork
                        self.displayedNetwork = updatedNetwork
                    }
                } else if isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        
                        Text("Generating Paper Network...")
                            .font(.headline)
                        
                        Text("Fetching related papers and calculating similarities")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    EmptyNetworkView(
                        errorMessage: errorMessage,
                        onStartAnalysis: { showInputForm = true }
                    )
                }
            }
            .navigationTitle("Paper Network Analysis")
            .navigationBarItems(
                leading: Button("Close") { onDismiss() },
                trailing: HStack {
                    if network != nil {
                        Button("Filters") { showFilters = true }
                    }
                    Button("New Analysis") { showInputForm = true }
                }
            )
        }
        .sheet(isPresented: $showInputForm) {
            PaperInputForm { paperInput in
                generateNetwork(from: paperInput)
            }
        }
        .sheet(isPresented: $showFilters) {
            if let network = network {
                NetworkFilterView(
                    filters: $filters,
                    network: network,
                    onApplyFilters: applyFilters
                )
            }
        }
        .sheet(isPresented: $showVisualization) {
            if let visualizationData = visualizationData {
                CollectionVisualizationView(
                    visualization: visualizationData,
                    title: "Collection Network Analysis",
                    onDismiss: { showVisualization = false }
                )
            }
        }
    }
    
    private func generateNetwork(from input: PaperInput) {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                // Call collection analysis instead of paper network
                let visualization = try await APIService.shared.generateCollectionAnalysis(
                    userAbstract: input.text,
                    userTitle: "User Input: \(input.inputType.displayName)"
                )
                
                // Navigate to visualization view
                await MainActor.run {
                    isLoading = false
                    showVisualization(with: visualization)
                }
                
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Error generating analysis: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func showVisualization(with visualization: VisualizationResponse) {
        visualizationData = visualization
        showVisualization = true
    }
    
    private func applyFilters(_ filters: NetworkFilters) {
        guard let originalNetwork = network else { return }
        displayedNetwork = filters.apply(to: originalNetwork)
        showFilters = false
    }
}

struct EmptyNetworkView: View {
    let errorMessage: String
    let onStartAnalysis: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "network")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            VStack(spacing: 16) {
                Text("Paper Network Analysis")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Discover connections between research papers using AI-powered similarity analysis")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
            }
            
            VStack(spacing: 16) {
                Text("Features:")
                    .font(.headline)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    FeatureCard(
                        icon: "magnifyingglass",
                        title: "Smart Discovery",
                        description: "Find related papers using semantic similarity"
                    )
                    
                    FeatureCard(
                        icon: "circle.hexagongrid.fill",
                        title: "Topic Clustering",
                        description: "Group papers by research themes"
                    )
                    
                    FeatureCard(
                        icon: "link",
                        title: "Connection Mapping",
                        description: "Visualize relationships between papers"
                    )
                    
                    FeatureCard(
                        icon: "slider.horizontal.3",
                        title: "Advanced Filters",
                        description: "Filter by date, author, source, and more"
                    )
                }
            }
            .padding(.horizontal)
            
            Button(action: onStartAnalysis) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Start Network Analysis")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
            
            Spacer()
        }
        .padding()
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.blue)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}