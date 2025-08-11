import SwiftUI
import Charts

struct CollectionVisualizationView: View {
    @State private var selectedPoint: VisualizationPoint?
    @State private var showPointDetails = false
    
    let visualization: VisualizationResponse
    let title: String
    let selectedCollection: Collection?
    let onDismiss: () -> Void
    
    init(visualization: VisualizationResponse, title: String = "Collection Analysis", selectedCollection: Collection? = nil, onDismiss: @escaping () -> Void) {
        self.visualization = visualization
        self.title = title
        self.selectedCollection = selectedCollection
        self.onDismiss = onDismiss
    }
    
    private func pointMarks(for points: [VisualizationPoint], colorMapping: [String: Color]) -> some ChartContent {
        ForEach(points) { point in
            PointMark(x: .value("PC1", point.x), y: .value("PC2", point.y))
                .foregroundStyle(getColor(for: point, colorMapping: colorMapping))
                .symbolSize(getSymbolSize(for: point))
                .opacity(getOpacity(for: point))
                .symbol(getSymbol(for: point))
        }
    }
    
    private func getColor(for point: VisualizationPoint, colorMapping: [String: Color]) -> Color {
        if selectedPoint?.id == point.id {
            return .red
        }
        
        if isUserInputPoint(point) {
            return .gray
        }
        
        return colorMapping[point.clusterName] ?? .blue
    }
    
    private func isUserInputPoint(_ point: VisualizationPoint) -> Bool {
        // Checks if this is user input by cluster name since isUserInput field doesn't exist in VisualizationPoint
        return point.clusterName == "User Input" || point.clusterId == -1
    }
    
    private func getSymbol(for point: VisualizationPoint) -> BasicChartSymbolShape {
        if isUserInputPoint(point) {
            return .diamond  // Uses diamond for user input since star isn't available
        } else {
            return .circle
        }
    }
    
    private func getSymbolSize(for point: VisualizationPoint) -> CGFloat {
        if isUserInputPoint(point) {
            return selectedPoint?.id == point.id ? 800 : 600  // Makes it MUCH larger to ensure visibility
        } else {
            return selectedPoint?.id == point.id ? 250 : 200  // Regular dots
        }
    }
    
    private func getOpacity(for point: VisualizationPoint) -> Double {
        if isUserInputPoint(point) {
            return 0.8  // Less transparent for user input
        } else {
            return 0.5  // More transparent for papers
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
        let bounds = getChartBounds(for: viz)

        return Chart {
            pointMarks(for: viz.points, colorMapping: colorMapping)
            labelMarks(for: viz.points)
        }
        .chartXScale(domain: bounds.xRange)
        .chartYScale(domain: bounds.yRange)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                Spacer().frame(height: 60)
                
                // Title and Collection Info
                VStack(spacing: 8) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let collection = selectedCollection {
                        VStack(spacing: 4) {
                            Text("Target Collection")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(collection.title)
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                // Chart
                chartView(for: visualization)
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
                clusterLegend(for: visualization)
                
                // Statistics
                HStack {
                    Text("\(visualization.count) papers visualized")
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
                            VStack(alignment: .leading, spacing: 4) {
                                Text(selected.title)
                                    .font(.subheadline)
                                    .lineLimit(nil)
                                
                                if isUserInputPoint(selected) {
                                    Text("👤 User Input")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(4)
                                }
                            }
                            
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
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Back") {
                    onDismiss()
                }
            )
        }
        .sheet(isPresented: $showPointDetails) {
            if let selected = selectedPoint {
                NavigationView {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(selected.title)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            if isUserInputPoint(selected) {
                                Text("👤 User Input")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(4)
                            }
                            
                            Text("Full Text")
                                .font(.headline)
                            
                            Text(selected.fullText)
                                .font(.body)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            
                            Spacer()
                        }
                        .padding()
                    }
                    .navigationTitle("Paper Details")
                    .navigationBarItems(
                        trailing: Button("Done") {
                            showPointDetails = false
                        }
                    )
                }
            }
        }
    }
    
    private func getChartBounds(for viz: VisualizationResponse) -> (xRange: ClosedRange<Double>, yRange: ClosedRange<Double>) {
        // Find user input point
        guard let userPoint = viz.points.first(where: { isUserInputPoint($0) }) else {
            // Fallback to auto bounds if no user input
            return getAutoBounds(for: viz)
        }
        
        // Center around user input point
        let centerX = userPoint.x
        let centerY = userPoint.y
        
        // Calculate dynamic range based on data distribution
        let xValues = viz.points.map { $0.x }
        let yValues = viz.points.map { $0.y }
        
        // Calculate required range to include all points from user input center
        let maxDistanceX = max(abs((xValues.max() ?? centerX) - centerX), abs((xValues.min() ?? centerX) - centerX))
        let maxDistanceY = max(abs((yValues.max() ?? centerY) - centerY), abs((yValues.min() ?? centerY) - centerY))
        
        // Add padding and minimum range for each axis independently
        let paddingFactor = 1.1
        let minimumRange = 0.5
        
        let xRange = max(maxDistanceX * 2 * paddingFactor, minimumRange)
        let yRange = max(maxDistanceY * 2 * paddingFactor, minimumRange)
        
        let halfXRange = xRange / 2
        let halfYRange = yRange / 2
        
        return (
            xRange: (centerX - halfXRange)...(centerX + halfXRange),
            yRange: (centerY - halfYRange)...(centerY + halfYRange)
        )
    }
    
    private func getAutoBounds(for viz: VisualizationResponse) -> (xRange: ClosedRange<Double>, yRange: ClosedRange<Double>) {
        let xValues = viz.points.map { $0.x }
        let yValues = viz.points.map { $0.y }
        
        let minX = xValues.min() ?? -2
        let maxX = xValues.max() ?? 2
        let minY = yValues.min() ?? -2
        let maxY = yValues.max() ?? 2
        
        // Add some padding
        let xPadding = (maxX - minX) * 0.1
        let yPadding = (maxY - minY) * 0.1
        
        return (
            xRange: (minX - xPadding)...(maxX + xPadding),
            yRange: (minY - yPadding)...(maxY + yPadding)
        )
    }

    private func getClusterColors(for viz: VisualizationResponse) -> [String: Color] {
        let colors: [Color] = [.blue, .red, .green, .orange, .purple, .pink, .cyan, .yellow]
        let uniqueClusters = Array(Set(viz.points.map { $0.clusterName })).sorted()
        
        var colorMapping: [String: Color] = [:]
        for (index, clusterName) in uniqueClusters.enumerated() {
            if clusterName == "User Input" {
                colorMapping[clusterName] = .gray
            } else {
                colorMapping[clusterName] = colors[index % colors.count]
            }
        }
        return colorMapping
    }
    
    private func clusterLegend(for viz: VisualizationResponse) -> some View {
        let uniqueClusters = Array(Set(viz.points.map { $0.clusterName })).sorted()
        let colorMapping = getClusterColors(for: viz)
        
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(uniqueClusters, id: \.self) { clusterName in
                    HStack(spacing: 6) {
                        if clusterName == "User Input" {
                            Text("♦")
                                .foregroundColor(.gray)
                                .font(.caption)
                        } else {
                            Circle()
                                .fill(colorMapping[clusterName] ?? .blue)
                                .frame(width: 12, height: 12)
                        }
                        
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
    
    private func findNearestPoint(at location: CGPoint, geometry: GeometryProxy, chartProxy: ChartProxy) {
        var nearestPoint: VisualizationPoint?
        var minDistance: Double = .infinity
        
        for point in visualization.points {
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
