import SwiftUI

struct NetworkFilterView: View {
    @Binding var filters: NetworkFilters
    let network: PaperNetwork
    let onApplyFilters: (NetworkFilters) -> Void
    
    @State private var tempFilters: NetworkFilters
    @State private var showDatePicker = false
    
    init(filters: Binding<NetworkFilters>, network: PaperNetwork, onApplyFilters: @escaping (NetworkFilters) -> Void) {
        self._filters = filters
        self.network = network
        self.onApplyFilters = onApplyFilters
        self._tempFilters = State(initialValue: filters.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Date Range")) {
                    Toggle("Filter by Date", isOn: $tempFilters.filterByDate)
                    
                    if tempFilters.filterByDate {
                        DatePicker("From", selection: $tempFilters.dateFrom, displayedComponents: .date)
                        DatePicker("To", selection: $tempFilters.dateTo, displayedComponents: .date)
                    }
                }
                
                Section(header: Text("Topic Clusters")) {
                    Toggle("Filter by Clusters", isOn: $tempFilters.filterByClusters)
                    
                    if tempFilters.filterByClusters {
                        ForEach(network.clusters) { cluster in
                            HStack {
                                Circle()
                                    .fill(cluster.color.swiftUIColor)
                                    .frame(width: 16, height: 16)
                                
                                Text(cluster.label)
                                    .font(.body)
                                
                                Spacer()
                                
                                Toggle("", isOn: binding(for: cluster.id))
                                    .labelsHidden()
                            }
                        }
                    }
                }
                
                Section(header: Text("Authors")) {
                    Toggle("Filter by Authors", isOn: $tempFilters.filterByAuthors)
                    
                    if tempFilters.filterByAuthors {
                        HStack {
                            TextField("Enter author names", text: $tempFilters.authorQuery)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            if !tempFilters.authorQuery.isEmpty {
                                Button("Clear") {
                                    tempFilters.authorQuery = ""
                                }
                                .foregroundColor(.red)
                            }
                        }
                        
                        Text("Separate multiple authors with commas")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Sources")) {
                    Toggle("Filter by Sources", isOn: $tempFilters.filterBySources)
                    
                    if tempFilters.filterBySources {
                        ForEach(availableSources, id: \.self) { source in
                            HStack {
                                Text(source)
                                Spacer()
                                Toggle("", isOn: binding(for: source, in: \.selectedSources))
                                    .labelsHidden()
                            }
                        }
                    }
                }
                
                Section(header: Text("Similarity Threshold")) {
                    Toggle("Filter by Similarity", isOn: $tempFilters.filterBySimilarity)
                    
                    if tempFilters.filterBySimilarity {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Minimum Similarity: \(Int(tempFilters.similarityThreshold * 100))%")
                                .font(.subheadline)
                            
                            Slider(value: $tempFilters.similarityThreshold, in: 0...1, step: 0.05)
                                .accentColor(.blue)
                        }
                    }
                }
                
                Section(header: Text("Connection Types")) {
                    Toggle("Filter by Edge Types", isOn: $tempFilters.filterByEdgeTypes)
                    
                    if tempFilters.filterByEdgeTypes {
                        ForEach(NetworkEdge.EdgeType.allCases, id: \.self) { edgeType in
                            HStack {
                                Circle()
                                    .fill(edgeType.color)
                                    .frame(width: 16, height: 16)
                                
                                Text(edgeType.displayName)
                                    .font(.body)
                                
                                Spacer()
                                
                                Toggle("", isOn: binding(for: edgeType.rawValue, in: \.selectedEdgeTypes))
                                    .labelsHidden()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Network Filters")
            .navigationBarItems(
                leading: Button("Cancel") {
                    tempFilters = filters
                },
                trailing: Button("Apply") {
                    filters = tempFilters
                    onApplyFilters(tempFilters)
                }
            )
        }
    }
    
    private var availableSources: [String] {
        let sources = Set(network.nodes.compactMap { $0.source })
        return Array(sources).sorted()
    }
    
    private func binding(for clusterId: String) -> Binding<Bool> {
        Binding<Bool>(
            get: { tempFilters.selectedClusters.contains(clusterId) },
            set: { isSelected in
                if isSelected {
                    tempFilters.selectedClusters.insert(clusterId)
                } else {
                    tempFilters.selectedClusters.remove(clusterId)
                }
            }
        )
    }
    
    private func binding<T: Hashable>(for item: T, in keyPath: WritableKeyPath<NetworkFilters, Set<T>>) -> Binding<Bool> {
        Binding<Bool>(
            get: { tempFilters[keyPath: keyPath].contains(item) },
            set: { isSelected in
                if isSelected {
                    tempFilters[keyPath: keyPath].insert(item)
                } else {
                    tempFilters[keyPath: keyPath].remove(item)
                }
            }
        )
    }
}

struct NetworkFilters {
    var filterByDate = false
    var dateFrom = Calendar.current.date(byAdding: .year, value: -5, to: Date()) ?? Date()
    var dateTo = Date()
    
    var filterByClusters = false
    var selectedClusters: Set<String> = []
    
    var filterByAuthors = false
    var authorQuery = ""
    
    var filterBySources = false
    var selectedSources: Set<String> = []
    
    var filterBySimilarity = false
    var similarityThreshold: Double = 0.3
    
    var filterByEdgeTypes = false
    var selectedEdgeTypes: Set<String> = []
    
    func apply(to network: PaperNetwork) -> PaperNetwork {
        var filteredNodes = network.nodes
        var filteredEdges = network.edges
        
        if filterByDate {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            filteredNodes = filteredNodes.filter { node in
                guard let dateString = node.publicationDate,
                      let nodeDate = dateFormatter.date(from: dateString) else {
                    return true
                }
                return nodeDate >= dateFrom && nodeDate <= dateTo
            }
        }
        
        if filterByClusters && !selectedClusters.isEmpty {
            filteredNodes = filteredNodes.filter { node in
                guard let clusterId = node.clusterId else { return false }
                return selectedClusters.contains(clusterId)
            }
        }
        
        if filterByAuthors && !authorQuery.isEmpty {
            let queryTerms = authorQuery.lowercased()
                .components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            
            filteredNodes = filteredNodes.filter { node in
                guard let authors = node.authors?.lowercased() else { return false }
                return queryTerms.contains { authors.contains($0) }
            }
        }
        
        if filterBySources && !selectedSources.isEmpty {
            filteredNodes = filteredNodes.filter { node in
                guard let source = node.source else { return false }
                return selectedSources.contains(source)
            }
        }
        
        if filterBySimilarity {
            filteredNodes = filteredNodes.filter { node in
                guard let similarity = node.similarity else { return true }
                return similarity >= similarityThreshold
            }
        }
        
        let filteredNodeIds = Set(filteredNodes.map { $0.id })
        
        filteredEdges = filteredEdges.filter { edge in
            let hasValidNodes = filteredNodeIds.contains(edge.sourceId) && 
                               filteredNodeIds.contains(edge.targetId)
            
            if filterByEdgeTypes && !selectedEdgeTypes.isEmpty {
                return hasValidNodes && selectedEdgeTypes.contains(edge.edgeType.rawValue)
            }
            
            return hasValidNodes
        }
        
        let filteredClusters = network.clusters.filter { cluster in
            !Set(cluster.nodeIds).isDisjoint(with: filteredNodeIds)
        }
        
        return PaperNetwork(
            inputPaper: network.inputPaper,
            nodes: filteredNodes,
            edges: filteredEdges,
            clusters: filteredClusters,
            similarities: network.similarities,
            embeddings: network.embeddings
        )
    }
}