import SwiftUI
import Charts

struct EmbeddingVisualizationView: View {
    @State private var visualization: VisualizationResponse?
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var selectedPoint: VisualizationPoint?
    @State private var showPointDetails = false
    
    let papers: [(title: String, abstract: String)]
    let title: String
    let onDismiss: () -> Void
    
    init(papers: [(title: String, abstract: String)], title: String = "Embedding Visualization", onDismiss: @escaping () -> Void) {
        self.papers = papers
        self.title = title
        self.onDismiss = onDismiss
    }
    
    private func pointMarks(for points: [VisualizationPoint], colorMapping: [String: Color]) -> some ChartContent {
        ForEach(points) { point in
            PointMark(x: .value("PC1", point.x), y: .value("PC2", point.y))
                .foregroundStyle(selectedPoint?.id == point.id ? .red : (colorMapping[point.clusterName] ?? .blue))
                .symbolSize(selectedPoint?.id == point.id ? 250 : 200)
                .opacity(0.5)
        }
    }
    
    private func labelMarks(for points: [VisualizationPoint]) -> some ChartContent {
        ForEach(points) { point in
            PointMark(x: .value("PC1", point.x), y: .value("PC2", point.y))
                .symbol(.circle)
                .symbolSize(0)
                .annotation(position: .top, alignment: .center) {
                    paperTitleLabel(for: point)
                }
        }
    }
    
    
    private func chartView(for viz: VisualizationResponse) -> some View {
        let colorMapping = getClusterColors(for: viz)
        
        return Chart {
            pointMarks(for: viz.points, colorMapping: colorMapping)
            labelMarks(for: viz.points)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                if isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        
                        Text("Generating embeddings...")
                            .font(.headline)
                        
                        Text("Using AI to analyze \(papers.count) paper\(papers.count == 1 ? "" : "s")")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                } else if let viz = visualization {
                    Spacer().frame(height: 30)
                    
                    // Chart
                    chartView(for: viz)
                    .chartXAxis(.hidden)
                    .chartYAxis(.hidden)
                    .chartBackground { chartProxy in
                        GeometryReader { geometry in
                            Rectangle()
                                .fill(.clear)
                                .contentShape(Rectangle())
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onEnded { value in
                                            findNearestPoint(at: value.location, geometry: geometry, chartProxy: chartProxy)
                                        }
                                )
                        }
                    }
                    .frame(height: 600)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Legend
                    clusterLegend(for: viz)
                    
                    // Statistics
                    HStack {
                        Text("\(viz.count) papers visualized")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    
                    // Selected point details
                    if let selected = selectedPoint {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(selected.title)
                                    .font(.subheadline)
                                    .lineLimit(nil)
                                Spacer()
                                Button("Full Text") {
                                    showPointDetails = true
                                }
                                .buttonStyle(.bordered)
                            }
                            
                            ScrollView {
                                Text(selected.fullText)
                                    .font(.body)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                            }
                            .frame(maxHeight: 120)
                            
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                    }
                    
                    Spacer()
                    
                } else {
                    // Error or empty state
                    VStack(spacing: 20) {
                        Image(systemName: errorMessage.isEmpty ? "chart.dots.scatter" : "exclamationmark.triangle")
                            .font(.system(size: 60))
                            .foregroundColor(errorMessage.isEmpty ? .blue : .red)
                        
                        Text(errorMessage.isEmpty ? "Ready to visualize" : "Error")
                            .font(.headline)
                        
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(.body)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        Button("Generate Visualization") {
                            generateVisualization()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding()
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Back") {
                    onDismiss()
                }
            )
        }
        .sheet(isPresented: $showPointDetails) {
            if let selected = selectedPoint {
                PointDetailsView(point: selected)
            }
        }
    }
    
    private func getClusterColors(for viz: VisualizationResponse) -> [String: Color] {
        let colors: [Color] = [.blue, .red, .green, .orange, .purple, .pink, .cyan, .yellow]
        let uniqueClusters = Array(Set(viz.points.map { $0.clusterName })).sorted()
        
        var colorMapping: [String: Color] = [:]
        for (index, clusterName) in uniqueClusters.enumerated() {
            colorMapping[clusterName] = colors[index % colors.count]
        }
        return colorMapping
    }
    
    private func colorForCluster(_ clusterName: String) -> Color {
        // This will be overridden by the color mapping in chart context
        return .blue
    }
    
    private func clusterLegend(for viz: VisualizationResponse) -> some View {
        let uniqueClusters = Array(Set(viz.points.map { $0.clusterName })).sorted()
        let colorMapping = getClusterColors(for: viz)
        
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(uniqueClusters, id: \.self) { clusterName in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(colorMapping[clusterName] ?? .blue)
                            .frame(width: 12, height: 12)
                        
                        Text(clusterName)
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(colorMapping[clusterName] ?? .blue, lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 30)
    }
    
    private func paperTitleLabel(for point: VisualizationPoint) -> some View {
        Text(point.text)
            .font(.caption2)
            .foregroundColor(selectedPoint?.id == point.id ? .red : .primary)
            .opacity(0.6)
            .padding(2)
            .background(Color(.systemBackground).opacity(0.3))
            .cornerRadius(4)
    }
    
    
    
    private func generateVisualization() {
        guard papers.count >= 2 else {
            errorMessage = "Need at least 2 texts for visualization"
            return
        }
        
        isLoading = true
        errorMessage = ""
        selectedPoint = nil
        
        Task {
            do {
                let response = try await APIService.shared.mapNetworks(papers: papers)
                await MainActor.run {
                    visualization = response
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to generate visualization: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    private func findNearestPoint(at location: CGPoint, geometry: GeometryProxy, chartProxy: ChartProxy) {
        guard let viz = visualization else { return }
        
        var nearestPoint: VisualizationPoint?
        var minDistance: Double = .infinity
        
        for point in viz.points {
            if let plotX = chartProxy.position(forX: point.x),
               let plotY = chartProxy.position(forY: point.y) {
                
                let distance = sqrt(pow(plotX - location.x, 2) + pow(plotY - location.y, 2))
                if distance < minDistance {
                    minDistance = distance
                    nearestPoint = point
                }
            }
        }
        
        if minDistance < 30 { // Within 30 points
            selectedPoint = nearestPoint
        }
    }
}

struct PointDetailsView: View {
    let point: VisualizationPoint
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(point.title)
                        .font(.headline)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Full Text")
                        .font(.headline)
                    
                    ScrollView {
                        Text(point.fullText)
                            .font(.body)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
                
                Spacer()
                
                Button("Copy Text") {
                    UIPasteboard.general.string = point.fullText
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .navigationTitle("Point Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

