//
//  SEarchResultItem.swift
//  front-end-whisper-tree
//
//  Created by Valzhina on 7/25/25.
//


import Foundation

struct SearchResultItem: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let abstract: String?
    let authors: String?
    let publicationDate: String?
    let downloadUrl: String?
    let coreId: String?
    let source: String
    let url: String?
    let likesCount: Int
    
    enum CodingKeys: String, CodingKey {
        case title
        case abstract
        case authors
        case publicationDate = "publication_date"
        case downloadUrl = "download_url"
        case coreId = "core_id"
        case source
        case url
        case likesCount = "likes_count"
    }
    
    // Manual initializer for creating papers manually (not from CORE API)
    init(title: String, abstract: String? = nil, authors: String? = nil,
         publicationDate: String? = nil, source: String, url: String? = nil,
         downloadUrl: String? = nil, coreId: String? = nil, likesCount: Int = 0) {
        self.title = title
        self.abstract = abstract
        self.authors = authors
        self.publicationDate = publicationDate
        self.downloadUrl = downloadUrl
        self.coreId = coreId
        self.source = source
        self.url = url
        self.likesCount = likesCount
        
        // Use core_id as the id if available, otherwise use title as fallback
        if let coreIdValue = coreId, !coreIdValue.isEmpty {
            self.id = coreIdValue
        } else {
            self.id = title
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        title = try container.decode(String.self, forKey: .title)
        abstract = try container.decodeIfPresent(String.self, forKey: .abstract)
        authors = try container.decodeIfPresent(String.self, forKey: .authors)
        publicationDate = try container.decodeIfPresent(String.self, forKey: .publicationDate)
        downloadUrl = try container.decodeIfPresent(String.self, forKey: .downloadUrl)
        
        // Handle core_id which can be either String or Int from backend
        if let coreIdInt = try? container.decode(Int.self, forKey: .coreId) {
            coreId = String(coreIdInt)
        } else {
            coreId = try container.decodeIfPresent(String.self, forKey: .coreId)
        }
        
        // Set source to a default value if not provided
        source = try container.decodeIfPresent(String.self, forKey: .source) ?? "CORE API"
        url = try container.decodeIfPresent(String.self, forKey: .url)
        likesCount = try container.decodeIfPresent(Int.self, forKey: .likesCount) ?? 0
        
        // Use core_id as the id if available, otherwise use title as fallback
        if let coreIdValue = coreId, !coreIdValue.isEmpty {
            id = coreIdValue
        } else {
            id = title
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(abstract, forKey: .abstract)
        try container.encodeIfPresent(authors, forKey: .authors)
        try container.encodeIfPresent(publicationDate, forKey: .publicationDate)
        try container.encodeIfPresent(downloadUrl, forKey: .downloadUrl)
        try container.encodeIfPresent(coreId, forKey: .coreId)
        try container.encode(source, forKey: .source)
        try container.encodeIfPresent(url, forKey: .url)
        try container.encode(likesCount, forKey: .likesCount)
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: SearchResultItem, rhs: SearchResultItem) -> Bool {
        return lhs.id == rhs.id
    }
}
