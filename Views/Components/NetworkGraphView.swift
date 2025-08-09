import SwiftUI

struct NetworkGraphView: View {
    @State private var network: PaperNetwork
    @State private var selectedNodeId: String?
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var showNodeDetails = false
    @State private var hoveredNodeId: String?
    @State private var nodeTooltips: [String: String] = [:]
    @State private var isLoadingTooltip = false
    @State private var isExpandingNetwork = false
    
    let onNetworkUpdate: (PaperNetwork) -> Void
    
    init(network: PaperNetwork, onNetworkUpdate: @escaping (PaperNetwork) -> Void = { _ in }) {
        self._network = State(initialValue: network)
        self.onNetworkUpdate = onNetworkUpdate
    }
    
    private let nodeRadius: CGFloat = 20
    private let canvasSize: CGSize = CGSize(width: 800, height: 600)
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                ScrollView([.horizontal, .vertical]) {
                    ZStack {
                        ForEach(network.edges) { edge in
                            EdgeView(
                                edge: edge,
                                sourceNode: network.getNode(by: edge.sourceId),
                                targetNode: network.getNode(by: edge.targetId),
                                canvasSize: canvasSize,
                                scale: scale
                            )
                        }
                        
                        ForEach(network.nodes) { node in
                            NodeView(
                                node: node,
                                cluster: network.getCluster(for: node.id),
                                isSelected: selectedNodeId == node.id,
                                isHovered: hoveredNodeId == node.id,
                                canvasSize: canvasSize,
                                radius: nodeRadius,
                                onTap: { selectNode(node.id) },
                                onHover: { hoveredNodeId = $0 ? node.id : nil },
                                onDoubleTab: { expandNode(node.id) }
                            )
                        }
                    }
                    .frame(width: canvasSize.width * scale, height: canvasSize.height * scale)
                    .scaleEffect(scale)
                    .offset(offset)
                }
                .clipped()
                
                VStack {
                    HStack {
                        NetworkControlsView(
                            scale: $scale,
                            onResetView: resetView,
                            onFitToScreen: fitToScreen
                        )
                        Spacer()
                        NetworkLegendView(clusters: network.clusters)
                    }
                    .padding()
                    
                    Spacer()
                    
                    if let selectedNodeId = selectedNodeId,
                       let selectedNode = network.getNode(by: selectedNodeId) {
                        NodeDetailsView(
                            node: selectedNode,
                            cluster: network.getCluster(for: selectedNodeId),
                            connectedNodes: network.getConnectedNodes(for: selectedNodeId),
                            onClose: { self.selectedNodeId = nil }
                        )
                        .transition(.move(edge: .bottom))
                    }
                }
            }
        }
        .navigationTitle("Paper Network")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func selectNode(_ nodeId: String) {
        if selectedNodeId == nodeId {
            selectedNodeId = nil
        } else {
            selectedNodeId = nodeId
            centerOnNode(nodeId)
        }
    }
    
    private func centerOnNode(_ nodeId: String) {
        guard let node = network.getNode(by: nodeId) else { return }
        
        let centerX = canvasSize.width / 2
        let centerY = canvasSize.height / 2
        let nodeX = CGFloat(node.position.x) * canvasSize.width
        let nodeY = CGFloat(node.position.y) * canvasSize.height
        
        withAnimation(.easeInOut(duration: 0.5)) {
            offset = CGSize(
                width: centerX - nodeX,
                height: centerY - nodeY
            )
        }
    }
    
    private func resetView() {
        withAnimation(.easeInOut(duration: 0.5)) {
            scale = 1.0
            offset = .zero
        }
    }
    
    private func fitToScreen() {
        withAnimation(.easeInOut(duration: 0.5)) {
            scale = 0.8
            offset = .zero
        }
    }
    
    private func expandNode(_ nodeId: String) {
        guard !isExpandingNetwork else { return }
        
        isExpandingNetwork = true
        Task {
            do {
                let expandedNetwork = try await APIService.shared.expandNetwork(
                    from: nodeId,
                    in: network,
                    limit: 20
                )
                
                await MainActor.run {
                    network = expandedNetwork
                    onNetworkUpdate(expandedNetwork)
                    isExpandingNetwork = false
                }
            } catch {
                await MainActor.run {
                    isExpandingNetwork = false
                    print("Error expanding network: \(error)")
                }
            }
        }
    }
    
    private func loadTooltip(for nodeId: String) {
        guard nodeTooltips[nodeId] == nil, !isLoadingTooltip else { return }
        guard let node = network.getNode(by: nodeId) else { return }
        
        isLoadingTooltip = true
        Task {
            do {
                let summary = try await APIService.shared.generatePaperSummary(for: node)
                
                await MainActor.run {
                    nodeTooltips[nodeId] = summary
                    isLoadingTooltip = false
                }
            } catch {
                await MainActor.run {
                    nodeTooltips[nodeId] = "Summary unavailable"
                    isLoadingTooltip = false
                }
            }
        }
    }
}

struct NodeView: View {
    let node: NetworkNode
    let cluster: PaperCluster?
    let isSelected: Bool
    let isHovered: Bool
    let canvasSize: CGSize
    let radius: CGFloat
    let onTap: () -> Void
    let onHover: (Bool) -> Void
    let onDoubleTab: () -> Void
    
    var body: some View {
        ZStack {
            Circle()
                .fill(nodeColor)
                .frame(width: nodeSize, height: nodeSize)
                .overlay(
                    Circle()
                        .stroke(borderColor, lineWidth: borderWidth)
                )
            
            if node.isInputNode {
                Image(systemName: "star.fill")
                    .foregroundColor(.white)
                    .font(.system(size: radius * 0.6))
            }
        }
        .position(
            x: CGFloat(node.position.x) * canvasSize.width,
            y: CGFloat(node.position.y) * canvasSize.height
        )
        .scaleEffect(isHovered ? 1.2 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onTapGesture { onTap() }
        .onTapGesture(count: 2) { onDoubleTab() }
        .onHover { onHover($0) }
    }
    
    private var nodeColor: Color {
        if node.isInputNode {
            return .purple
        } else if let cluster = cluster {
            return cluster.color.swiftUIColor
        } else {
            return .gray
        }
    }
    
    private var borderColor: Color {
        if isSelected {
            return .primary
        } else if isHovered {
            return .secondary
        } else {
            return .clear
        }
    }
    
    private var borderWidth: CGFloat {
        if isSelected {
            return 3
        } else if isHovered {
            return 2
        } else {
            return 0
        }
    }
    
    private var nodeSize: CGFloat {
        let baseSize = radius * 2
        if node.isInputNode {
            return baseSize * 1.3
        } else {
            return baseSize
        }
    }
}

struct EdgeView: View {
    let edge: NetworkEdge
    let sourceNode: NetworkNode?
    let targetNode: NetworkNode?
    let canvasSize: CGSize
    let scale: CGFloat
    
    var body: some View {
        if let source = sourceNode, let target = targetNode {
            Path { path in
                let startPoint = CGPoint(
                    x: CGFloat(source.position.x) * canvasSize.width,
                    y: CGFloat(source.position.y) * canvasSize.height
                )
                let endPoint = CGPoint(
                    x: CGFloat(target.position.x) * canvasSize.width,
                    y: CGFloat(target.position.y) * canvasSize.height
                )
                
                path.move(to: startPoint)
                path.addLine(to: endPoint)
            }
            .stroke(edge.edgeType.color.opacity(edgeOpacity), lineWidth: edgeWidth)
        }
    }
    
    private var edgeOpacity: Double {
        min(0.8, max(0.2, edge.weight))
    }
    
    private var edgeWidth: CGFloat {
        let baseWidth: CGFloat = 1.0
        let weightMultiplier = CGFloat(edge.weight)
        return baseWidth + (weightMultiplier * 2)
    }
}

struct NetworkControlsView: View {
    @Binding var scale: CGFloat
    let onResetView: () -> Void
    let onFitToScreen: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Button(action: { scale = min(scale * 1.2, 3.0) }) {
                    Image(systemName: "plus.magnifyingglass")
                        .foregroundColor(.blue)
                }
                
                Button(action: { scale = max(scale * 0.8, 0.3) }) {
                    Image(systemName: "minus.magnifyingglass")
                        .foregroundColor(.blue)
                }
                
                Button(action: onResetView) {
                    Image(systemName: "arrow.counterclockwise")
                        .foregroundColor(.blue)
                }
                
                Button(action: onFitToScreen) {
                    Image(systemName: "rectangle.compress.vertical")
                        .foregroundColor(.blue)
                }
            }
            
            Text("Zoom: \(String(format: "%.0f", scale * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(8)
        .background(Color(.systemBackground).opacity(0.9))
        .cornerRadius(8)
        .shadow(radius: 2)
    }
}

struct NetworkLegendView: View {
    let clusters: [PaperCluster]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Clusters")
                .font(.caption.bold())
                .foregroundColor(.primary)
            
            ForEach(clusters.prefix(5)) { cluster in
                HStack(spacing: 6) {
                    Circle()
                        .fill(cluster.color.swiftUIColor)
                        .frame(width: 12, height: 12)
                    
                    Text(cluster.label)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            if clusters.count > 5 {
                Text("... and \(clusters.count - 5) more")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(8)
        .background(Color(.systemBackground).opacity(0.9))
        .cornerRadius(8)
        .shadow(radius: 2)
    }
}

struct NodeDetailsView: View {
    let node: NetworkNode
    let cluster: PaperCluster?
    let connectedNodes: [NetworkNode]
    let onClose: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        if node.isInputNode {
                            Image(systemName: "star.fill")
                                .foregroundColor(.purple)
                        }
                        Text(node.title)
                            .font(.headline)
                            .lineLimit(2)
                    }
                    
                    if let authors = node.authors {
                        Text(authors)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.title2)
                }
            }
            
            HStack {
                if let cluster = cluster {
                    Label(cluster.label, systemImage: "circle.fill")
                        .font(.caption)
                        .foregroundColor(cluster.color.swiftUIColor)
                }
                
                if let similarity = node.similarity {
                    Label("\(Int(similarity * 100))% similar", systemImage: "link")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                Label("\(connectedNodes.count) connections", systemImage: "network")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let abstract = node.abstract, !abstract.isEmpty {
                Text(abstract)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 8)
        .padding(.horizontal)
    }
}