import Foundation

struct Paper: Codable, Identifiable, Hashable {
    let id: Int
    let title: String
    let abstract: String?
    let authors: String?
    let publicationDate: String?
    let source: String?
    let url: String?
    let downloadUrl: String?
    let coreId: String?
    let likesCount: Int
    let collectionId: Int?
    
    enum CodingKeys: String, CodingKey {
        case id = "paper_id"  // Backend sends "paper_id", not "id"
        case title
        case abstract
        case authors
        case publicationDate = "publication_date"
        case source
        case url = "URL"  // Keep this for manual papers
        case downloadUrl = "download_url"
        case coreId = "core_id"
        case likesCount = "likes_count"
        case collectionId = "collection_id"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        abstract = try container.decodeIfPresent(String.self, forKey: .abstract)
        authors = try container.decodeIfPresent(String.self, forKey: .authors)
        publicationDate = try container.decodeIfPresent(String.self, forKey: .publicationDate)
        source = try container.decodeIfPresent(String.self, forKey: .source)
        url = try container.decodeIfPresent(String.self, forKey: .url)
        downloadUrl = try container.decodeIfPresent(String.self, forKey: .downloadUrl)
        likesCount = try container.decodeIfPresent(Int.self, forKey: .likesCount) ?? 0
        collectionId = try container.decodeIfPresent(Int.self, forKey: .collectionId)
        
        // Handle core_id which can be either String or Int from backend
        if let coreIdInt = try? container.decode(Int.self, forKey: .coreId) {
            coreId = String(coreIdInt)
        } else {
            coreId = try container.decodeIfPresent(String.self, forKey: .coreId)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(abstract, forKey: .abstract)
        try container.encodeIfPresent(authors, forKey: .authors)
        try container.encodeIfPresent(publicationDate, forKey: .publicationDate)
        try container.encodeIfPresent(source, forKey: .source)
        try container.encodeIfPresent(url, forKey: .url)
        try container.encodeIfPresent(downloadUrl, forKey: .downloadUrl)
        try container.encodeIfPresent(coreId, forKey: .coreId)
        try container.encode(likesCount, forKey: .likesCount)
        try container.encodeIfPresent(collectionId, forKey: .collectionId)
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Paper, rhs: Paper) -> Bool {
        return lhs.id == rhs.id
    }
}
