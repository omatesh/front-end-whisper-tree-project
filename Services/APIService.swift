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
        print("📡 Loading collections from: \(url.absoluteString)")

        let (data, response) = try await URLSession.shared.data(from: url)

        if let httpResponse = response as? HTTPURLResponse {
            print("📡 loadCollections Status Code: \(httpResponse.statusCode)")
            guard (200..<300).contains(httpResponse.statusCode) else {
                if let errorJsonString = String(data: data, encoding: .utf8) {
                    print("🚨 loadCollections Error Response Body:\n\(errorJsonString)")
                }
                throw APIError.invalidResponse
            }
        }

        if let rawJSON = String(data: data, encoding: .utf8) {
            print("📦 loadCollections Raw JSON:\n\(rawJSON)")
        }

        let decoder = JSONDecoder()
        
        do {
            return try decoder.decode([Collection].self, from: data)
        } catch {
            print("❌ Decoding error in loadCollections: \(error)")
            throw APIError.decodingError(error)
        }
    }

    func fetchPapers(for collectionId: Int) async throws -> [Paper] {
        // FIXED: Use your existing collections endpoint (NOT core/collections)
        guard let url = URL(string: "\(baseURL)/collections/\(collectionId)/papers") else {
            print("❌ [FETCH PAPERS] Invalid URL construction")
            throw APIError.invalidURL
        }
        print("🎯 [FETCH PAPERS] Calling endpoint: \(url.absoluteString)")
        print("🎯 [FETCH PAPERS] Collection ID: \(collectionId)")

        let (data, response) = try await URLSession.shared.data(from: url)

        if let httpResponse = response as? HTTPURLResponse {
            print("📡 [FETCH PAPERS] Status Code: \(httpResponse.statusCode)")
            if !(200..<300).contains(httpResponse.statusCode) {
                if let errorJsonString = String(data: data, encoding: .utf8) {
                    print("🚨 [FETCH PAPERS] Error Response Body:\n\(errorJsonString)")
                }
                print("❌ [FETCH PAPERS] HTTP Error - Status: \(httpResponse.statusCode)")
                throw APIError.invalidResponse
            }
        }

        if let jsonString = String(data: data, encoding: .utf8) {
            print("📦 [FETCH PAPERS] Raw JSON Response:\n\(jsonString)")
        }

        // Your backend returns: {"collection_id": 1, "title": "...", "papers": [...]}
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
            print("✅ [FETCH PAPERS] Successfully decoded \(response.papers.count) papers")
            return response.papers
        } catch {
            print("❌ [FETCH PAPERS] Decoding error: \(error)")
            print("❌ [FETCH PAPERS] Decoding error details: \(error.localizedDescription)")
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

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse {
            print("📡 createCollection Status Code: \(httpResponse.statusCode)")
            guard (200..<300).contains(httpResponse.statusCode) else {
                if let errorJsonString = String(data: data, encoding: .utf8) {
                    print("🚨 createCollection Error Response Body:\n\(errorJsonString)")
                }
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
        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse {
            print("📡 deleteCollection Status Code: \(httpResponse.statusCode)")
            guard (200..<300).contains(httpResponse.statusCode) else {
                if let errorJsonString = String(data: data, encoding: .utf8) {
                    print("🚨 deleteCollection Error Response Body:\n\(errorJsonString)")
                }
                throw APIError.invalidResponse
            }
        }
    }

    // MARK: - Papers

    func addPaper(collectionId: Int, searchResult: SearchResultItem) async throws {
        print("🎯 addPaper called with coreId: '\(searchResult.coreId ?? "none")'")
        
        // Check if this is a CORE paper (has core_id)
        if let coreId = searchResult.coreId, !coreId.isEmpty {
            print("📡 Routing to CORE endpoint for paper with core_id: \(coreId)")
            return try await addCorePaper(coreId: coreId, collectionId: collectionId)
        } else {
            print("📡 Routing to regular endpoint for manual paper")
            return try await addManualPaper(collectionId: collectionId, searchResult: searchResult)
        }
    }

    // FIXED: Use your actual CORE papers endpoint
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

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse {
            print("📡 addCorePaper Status Code: \(httpResponse.statusCode)")
            guard (200..<300).contains(httpResponse.statusCode) else {
                if let errorJsonString = String(data: data, encoding: .utf8) {
                    print("🚨 addCorePaper Error Response Body:\n\(errorJsonString)")
                }
                throw APIError.invalidResponse
            }
        }
        print("✅ Successfully added CORE paper to collection")
    }

    // Use your existing manual papers endpoint
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
            "URL": searchResult.url ?? "", // Note: "URL" not "url" for your backend
            "likes_count": searchResult.likesCount
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse {
            print("📡 addManualPaper Status Code: \(httpResponse.statusCode)")
            guard (200..<300).contains(httpResponse.statusCode) else {
                if let errorJsonString = String(data: data, encoding: .utf8) {
                    print("🚨 addManualPaper Error Response Body:\n\(errorJsonString)")
                }
                throw APIError.invalidResponse
            }
        }
        print("✅ Successfully added manual paper to collection")
    }

    func deletePaper(id: Int) async throws {
        // Use your existing papers delete endpoint
        guard let url = URL(string: "\(baseURL)/papers/\(id)") else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse {
            print("📡 deletePaper Status Code: \(httpResponse.statusCode)")
            guard (200..<300).contains(httpResponse.statusCode) else {
                if let errorJsonString = String(data: data, encoding: .utf8) {
                    print("🚨 deletePaper Error Response Body:\n\(errorJsonString)")
                }
                throw APIError.invalidResponse
            }
        }
        
    }

    // MARK: - Core API Search Operations

    func searchCoreAPI(query: String, limit: Int) async throws -> [SearchResultItem] {
        guard let url = URL(string: "\(baseURL)/core/search") else {
            throw APIError.invalidURL
        }
        print("📡 Searching Core API via backend at: \(url.absoluteString) for '\(query)' with limit: \(limit)")

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

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse {
            print("📡 searchCoreAPI Status Code: \(httpResponse.statusCode)")
            guard (200..<300).contains(httpResponse.statusCode) else {
                if let errorJsonString = String(data: data, encoding: .utf8) {
                    print("🚨 searchCoreAPI Error Response Body:\n\(errorJsonString)")
                }
                throw APIError.invalidResponse
            }
        }

        if let rawJSON = String(data: data, encoding: .utf8) {
            print("📦 searchCoreAPI Raw JSON:\n\(rawJSON)")
        }

        let decoder = JSONDecoder()

        do {
            let results = try decoder.decode([SearchResultItem].self, from: data)
            print("✅ searchCoreAPI decoded \(results.count) results")
            return results
        } catch {
            print("❌ Decoding error in searchCoreAPI: \(error)")
            print("❌ Detailed error: \(error.localizedDescription)")
            if let decodingError = error as? DecodingError {
                print("❌ Decoding error details: \(decodingError)")
            }
            throw APIError.decodingError(error)
        }
    }
}
