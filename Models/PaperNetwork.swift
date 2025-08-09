import Foundation
import SwiftUI

struct PaperNetwork: Codable {
    let inputPaper: PaperInput
    let nodes: [NetworkNode]
    let edges: [NetworkEdge]
    let clusters: [PaperCluster]
    let similarities: [String: [String: Double]]
    let embeddings: [String: [Double]]
    
    enum CodingKeys: String, CodingKey {
        case inputPaper = "input_paper"
        case nodes, edges, clusters, similarities, embeddings
    }
}

struct NetworkNode: Codable, Identifiable {
    let id: String
    let paperId: Int?
    let title: String
    let abstract: String?
    let authors: String?
    let publicationDate: String?
    let source: String?
    let clusterId: String?
    let position: NodePosition
    let similarity: Double?
    let isInputNode: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, title, abstract, authors, source, position, similarity
        case paperId = "paper_id"
        case publicationDate = "publication_date"
        case clusterId = "cluster_id"
        case isInputNode = "is_input_node"
    }
}

struct NodePosition: Codable {
    let x: Double
    let y: Double
}

struct NetworkEdge: Codable, Identifiable {
    let id: String
    let sourceId: String
    let targetId: String
    let weight: Double
    let edgeType: EdgeType
    
    enum EdgeType: String, CaseIterable, Codable {
        case semantic = "semantic_similarity"
        case authorConnection = "author_connection"
        case citationLink = "citation_link"
        case topicSimilarity = "topic_similarity"
        case keyword = "keyword_match"
        
        var displayName: String {
            switch self {
            case .semantic:
                return "Semantic Similarity"
            case .authorConnection:
                return "Author Connection"
            case .citationLink:
                return "Citation Link"
            case .topicSimilarity:
                return "Topic Similarity"
            case .keyword:
                return "Keyword Match"
            }
        }
        
        var color: Color {
            switch self {
            case .semantic:
                return .blue
            case .authorConnection:
                return .green
            case .citationLink:
                return .orange
            case .topicSimilarity:
                return .purple
            case .keyword:
                return .red
            }
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id, weight
        case sourceId = "source_id"
        case targetId = "target_id"
        case edgeType = "edge_type"
    }
}

struct PaperCluster: Codable, Identifiable {
    let id: String
    let label: String
    let description: String?
    let nodeIds: [String]
    let centroid: [Double]
    let size: Int
    let color: ClusterColor
    
    enum ClusterColor: String, CaseIterable, Codable {
        case blue, red, green, orange, purple, pink, cyan, yellow
        
        var swiftUIColor: Color {
            switch self {
            case .blue: return .blue
            case .red: return .red
            case .green: return .green
            case .orange: return .orange
            case .purple: return .purple
            case .pink: return .pink
            case .cyan: return .cyan
            case .yellow: return .yellow
            }
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id, label, description, centroid, size, color
        case nodeIds = "node_ids"
    }
}

extension PaperNetwork {
    func getNode(by id: String) -> NetworkNode? {
        return nodes.first { $0.id == id }
    }
    
    func getEdges(for nodeId: String) -> [NetworkEdge] {
        return edges.filter { $0.sourceId == nodeId || $0.targetId == nodeId }
    }
    
    func getCluster(for nodeId: String) -> PaperCluster? {
        return clusters.first { $0.nodeIds.contains(nodeId) }
    }
    
    func getConnectedNodes(for nodeId: String) -> [NetworkNode] {
        let connectedIds = edges.compactMap { edge -> String? in
            if edge.sourceId == nodeId {
                return edge.targetId
            } else if edge.targetId == nodeId {
                return edge.sourceId
            }
            return nil
        }
        
        return nodes.filter { connectedIds.contains($0.id) }
    }
}