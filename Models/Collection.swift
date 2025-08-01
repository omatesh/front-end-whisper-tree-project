//
//  Collection.swift
//  front-end-whisper-tree
//
//  Created by Valzhina on 7/25/25.

import Foundation

struct Collection: Codable, Identifiable, Hashable {
    let id: Int
    let title: String
    let owner: String?
    let description: String
    let papersCount: Int
    var papers: [Paper]
    
    // Add convenience initializer for creating new instances
    init(id: Int, title: String, owner: String?, description: String, papersCount: Int, papers: [Paper]) {
        self.id = id
        self.title = title
        self.owner = owner
        self.description = description
        self.papersCount = papersCount
        self.papers = papers
    }

    enum CodingKeys: String, CodingKey {
        case id = "collection_id"  // Updated to match your backend
        case title, owner, description
        case papersCount = "papers_count"
        case papers
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        owner = try container.decodeIfPresent(String.self, forKey: .owner)
        description = try container.decode(String.self, forKey: .description)
        papersCount = try container.decode(Int.self, forKey: .papersCount)
        papers = try container.decodeIfPresent([Paper].self, forKey: .papers) ?? []
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(owner, forKey: .owner)
        try container.encode(description, forKey: .description)
        try container.encode(papersCount, forKey: .papersCount)
        try container.encode(papers, forKey: .papers)
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Collection, rhs: Collection) -> Bool {
        return lhs.id == rhs.id
    }
}
