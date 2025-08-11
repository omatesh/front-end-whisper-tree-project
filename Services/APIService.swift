//
//  APIService.swift
//  front-end-whisper-tree
//
//  Created by Valzhina on 7/25/25.
//

import Foundation

class APIService: ObservableObject {
    static let shared = APIService()

//    baseURL to run when backend is running on this:
//    flask run --host=0.0.0.0 --port=5000
    private let baseURL = "http://192.168.1.231:5000"
    
//    baseURL to run when backend is running on Render:
//    private let baseURL = "https://backend-whisper-tree-on-render.onrender.com"
    private init() {}

    // MARK: - Collection Operations

    func loadCollections() async throws -> [Collection] {
        guard let url = URL(string: "\(baseURL)/collections") else {
            throw APIError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        if let httpResponse = response as? HTTPURLResponse {
            guard (200..<300).contains(httpResponse.statusCode) else {
                throw APIError.invalidResponse
            }
        }


        let decoder = JSONDecoder()
        
        do {
            return try decoder.decode([Collection].self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    func fetchPapers(for collectionId: Int) async throws -> [Paper] {

        guard let url = URL(string: "\(baseURL)/collections/\(collectionId)/papers") else {
            throw APIError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        if let httpResponse = response as? HTTPURLResponse {
            if !(200..<300).contains(httpResponse.statusCode) {
                throw APIError.invalidResponse
            }
        }


        // backend returns: {"collection_id": 1, "title": "...", "papers": [...]}
        struct CollectionWithPapersResponse: Codable {
            let collectionId: Int
            let title: String
            let owner: String?
            let description: String
            let papers: [Paper]
            
            enum CodingKeys: String, CodingKey {
                case collectionId = "collection_id"
                case title, owner, description, papers
            }
        }

        let decoder = JSONDecoder()

        do {
            let response = try decoder.decode(CollectionWithPapersResponse.self, from: data)
            return response.papers
        } catch {
            throw APIError.decodingError(error)
        }
    }

    func createCollection(title: String, owner: String, description: String) async throws {
        guard let url = URL(string: "\(baseURL)/collections") else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["title": title, "owner": owner, "description": description]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request, delegate: nil)

        if let httpResponse = response as? HTTPURLResponse {
            guard (200..<300).contains(httpResponse.statusCode) else {
                throw APIError.invalidResponse
            }
        }
    }

    func deleteCollection(id: Int) async throws {
        guard let url = URL(string: "\(baseURL)/collections/\(id)") else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        let (data, response) = try await URLSession.shared.data(for: request, delegate: nil)

        if let httpResponse = response as? HTTPURLResponse {
            guard (200..<300).contains(httpResponse.statusCode) else {
                throw APIError.invalidResponse
            }
        }
    }

    // MARK: - Papers

    func addPaper(collectionId: Int, searchResult: SearchResultItem) async throws {
        
        // Check if this is a CORE paper (has core_id)
        if let coreId = searchResult.coreId, !coreId.isEmpty {
            return try await addCorePaper(coreId: coreId, collectionId: collectionId)
        } else {
            return try await addManualPaper(collectionId: collectionId, searchResult: searchResult)
        }
    }

    // Uses actual CORE papers endpoint
    private func addCorePaper(coreId: String, collectionId: Int) async throws {
        guard let apiURL = URL(string: "\(baseURL)/core/papers/\(coreId)/add-to-collection") else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "collection_id": collectionId
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request, delegate: nil)

        if let httpResponse = response as? HTTPURLResponse {
            guard (200..<300).contains(httpResponse.statusCode) else {
                throw APIError.invalidResponse
            }
        }
    }

    // Uses existing manual papers endpoint
    private func addManualPaper(collectionId: Int, searchResult: SearchResultItem) async throws {
        guard let apiURL = URL(string: "\(baseURL)/collections/\(collectionId)/papers") else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "title": searchResult.title,
            "abstract": searchResult.abstract ?? "",
            "authors": searchResult.authors ?? "",
            "publication_date": searchResult.publicationDate ?? "",
            "source": searchResult.source,
            "URL": searchResult.url ?? "", //"URL" not "url" for your backend
            "likes_count": searchResult.likesCount
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request, delegate: nil)

        if let httpResponse = response as? HTTPURLResponse {
            guard (200..<300).contains(httpResponse.statusCode) else {
                throw APIError.invalidResponse
            }
        }
    }

    func deletePaper(id: Int) async throws {
        // Uses existing papers delete endpoint
        guard let url = URL(string: "\(baseURL)/papers/\(id)") else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        let (data, response) = try await URLSession.shared.data(for: request, delegate: nil)

        if let httpResponse = response as? HTTPURLResponse {
            guard (200..<300).contains(httpResponse.statusCode) else {
                throw APIError.invalidResponse
            }
        }
        
    }

    func togglePaperStar(id: Int) async throws -> Bool {
        guard let url = URL(string: "\(baseURL)/papers/\(id)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        
        let (data, response) = try await URLSession.shared.data(for: request, delegate: nil)
        
        if let httpResponse = response as? HTTPURLResponse {
            guard (200..<300).contains(httpResponse.statusCode) else {
                throw APIError.invalidResponse
            }
        }
        
        // Parse response to get the new star status
        if let responseData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let isStarred = responseData["is_starred"] as? Bool {
            return isStarred
        }
        
        // Fallback: assumes it was toggled successfully
        return true
    }


    // MARK: - Embedding Visualization Operations
    
    func analyzeIdea(collectionId: Int, userIdea: String) async throws -> VisualizationResponse {
        guard let url = URL(string: "\(baseURL)/network/analyze-idea") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "collection_id": collectionId,
            "user_idea": userIdea
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request, delegate: nil)
        
        if let httpResponse = response as? HTTPURLResponse {
            guard (200..<300).contains(httpResponse.statusCode) else {
                // Try to parse error message from backend
                if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errorMessage = errorData["error"] as? String {
                    throw APIError.custom(errorMessage)
                }
                throw APIError.invalidResponse
            }
        }
        
        
        let decoder = JSONDecoder()
        do {
            let visualization = try decoder.decode(VisualizationResponse.self, from: data)
            return visualization
        } catch {
            throw APIError.decodingError(error)
        }
    }

    // MARK: - Core API Search Operations

    func searchCoreAPI(query: String, limit: Int) async throws -> [SearchResultItem] {
        guard let url = URL(string: "\(baseURL)/core/search") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let coreRequestParams: [String: Any] = [
            "query": query,
            "limit": limit
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: coreRequestParams, options: [])
        } catch {
            throw APIError.invalidRequest
        }

        let (data, response) = try await URLSession.shared.data(for: request, delegate: nil)

        if let httpResponse = response as? HTTPURLResponse {
            guard (200..<300).contains(httpResponse.statusCode) else {
                throw APIError.invalidResponse
            }
        }


        let decoder = JSONDecoder()

        do {
            let results = try decoder.decode([SearchResultItem].self, from: data)
            return results
        } catch {
            throw APIError.decodingError(error)
        }
    }
}
