//
//  APIError.swift
//  front-end-whisper-tree
//
//  Created by Valzhina on 7/25/25.
//

import Foundation

// Custom error types for API interactions

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidRequest
    case invalidResponse
    case decodingError(Error) // Wraps a decoding error for more detail
    case custom(String) // For general custom error messages

    // Provides a user-friendly description for each error type
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The API URL was malformed or invalid."
        case .invalidRequest:
            return "The request could not be properly formed or sent."
        case .invalidResponse:
            return "The server returned an unexpected or invalid response."
        case .decodingError(let error):
            return "Failed to process the server's data: \(error.localizedDescription)"
        case .custom(let message):
            return message
        }
    }
}
