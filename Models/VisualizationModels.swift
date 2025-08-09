import Foundation

struct VisualizationPoint: Codable, Identifiable {
    let id: Int
    let title: String
    let text: String
    let fullText: String
    let x: Double
    let y: Double
    let clusterId: Int
    let clusterName: String
    
    enum CodingKeys: String, CodingKey {
        case id, title, text, x, y
        case fullText = "full_text"
        case clusterId = "cluster_id"
        case clusterName = "cluster_name"
    }
}


struct VisualizationResponse: Codable {
    let points: [VisualizationPoint]
    let count: Int
    let method: String
    let pcaVariance: Double
    
    enum CodingKeys: String, CodingKey {
        case points, count, method
        case pcaVariance = "pca_variance"
    }
}