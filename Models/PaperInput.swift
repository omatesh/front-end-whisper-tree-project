import Foundation

struct PaperInput: Codable, Identifiable {
    let id: UUID
    let text: String
    let inputType: InputType
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case text
        case inputType = "input_type"
        case timestamp
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        text = try container.decode(String.self, forKey: .text)
        inputType = try container.decode(InputType.self, forKey: .inputType)
        timestamp = try container.decodeIfPresent(Date.self, forKey: .timestamp) ?? Date()
        id = UUID()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(text, forKey: .text)
        try container.encode(inputType, forKey: .inputType)
        try container.encode(timestamp, forKey: .timestamp)
    }
    
    enum InputType: String, CaseIterable, Codable {
        case title = "title"
        case abstract = "abstract"
        case keywords = "keywords"
        case topic = "topic"
        
        var displayName: String {
            switch self {
            case .title:
                return "Paper Title"
            case .abstract:
                return "Abstract"
            case .keywords:
                return "Keywords"
            case .topic:
                return "Research Topic"
            }
        }
    }
    
    init(text: String, inputType: InputType) {
        self.id = UUID()
        self.text = text
        self.inputType = inputType
        self.timestamp = Date()
    }
}