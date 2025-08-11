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
    var papers: [Paper]
    
    // Computed property that always reflects the actual number of papers
    var papersCount: Int {
        return papers.count
    }
    
    // Add convenience initializer for creating new instances
    init(id: Int, title: String, owner: String?, description: String, papers: [Paper]) {
        self.id = id
        self.title = title
        self.owner = owner
        self.description = description
        self.papers = papers
    }

    enum CodingKeys: String, CodingKey {
        case id = "collection_id"  // Updated to match your backend
        case title, owner, description
        case papers
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        owner = try container.decodeIfPresent(String.self, forKey: .owner)
        description = try container.decode(String.self, forKey: .description)
        papers = try container.decodeIfPresent([Paper].self, forKey: .papers) ?? []
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(owner, forKey: .owner)
        try container.encode(description, forKey: .description)
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
