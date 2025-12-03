//
//  APIClient.swift
//  alpha
//
//  Created by Claude Code on 11/25/25.
//

import Foundation
import Combine

enum APIError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case unauthorized
    case serverError(Int, String?)
    case decodingError(Error)
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .unauthorized:
            return "Unauthorized. Please log in again."
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message ?? "Unknown error")"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .noData:
            return "No data received from server"
        }
    }
}

@MainActor
class APIClient {
    static let shared = APIClient()

    private let baseURL = "http://localhost:8000/api/v1"
    private let session: URLSession

    // JSON decoder with custom date strategy
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            // Try various date formats
            let formatters: [(DateFormatter) -> Void] = [
                // ISO8601 with microseconds (6 digits)
                { formatter in
                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
                    formatter.locale = Locale(identifier: "en_US_POSIX")
                    formatter.timeZone = TimeZone(secondsFromGMT: 0)
                },
                // ISO8601 with milliseconds (3 digits)
                { formatter in
                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
                    formatter.locale = Locale(identifier: "en_US_POSIX")
                    formatter.timeZone = TimeZone(secondsFromGMT: 0)
                },
                // ISO8601 without fractional seconds
                { formatter in
                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                    formatter.locale = Locale(identifier: "en_US_POSIX")
                    formatter.timeZone = TimeZone(secondsFromGMT: 0)
                },
                // With timezone
                { formatter in
                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ"
                    formatter.locale = Locale(identifier: "en_US_POSIX")
                }
            ]

            for formatterConfig in formatters {
                let formatter = DateFormatter()
                formatterConfig(formatter)
                if let date = formatter.date(from: dateString) {
                    return date
                }
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date string: \(dateString)"
            )
        }
        return decoder
    }()

    // JSON encoder with custom date strategy
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            try container.encode(formatter.string(from: date))
        }
        return encoder
    }()

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: configuration)
    }

    // MARK: - Generic Request Methods

    func get<T: Decodable>(_ endpoint: String) async throws -> T {
        try await request(endpoint: endpoint, method: "GET", body: nil as String?)
    }

    func post<T: Decodable, B: Encodable>(_ endpoint: String, body: B) async throws -> T {
        try await request(endpoint: endpoint, method: "POST", body: body)
    }

    func put<T: Decodable, B: Encodable>(_ endpoint: String, body: B) async throws -> T {
        try await request(endpoint: endpoint, method: "PUT", body: body)
    }

    func delete<T: Decodable>(_ endpoint: String) async throws -> T {
        try await request(endpoint: endpoint, method: "DELETE", body: nil as String?)
    }

    func delete(_ endpoint: String) async throws {
        let _: EmptyResponse? = try await request(endpoint: endpoint, method: "DELETE", body: nil as String?)
    }

    // MARK: - Core Request Method

    private func request<T: Decodable, B: Encodable>(
        endpoint: String,
        method: String,
        body: B?
    ) async throws -> T {
        // Build URL
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add authorization token if available
        if let token = try? KeychainHelper.shared.getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Encode body if present
        if let body = body {
            do {
                request.httpBody = try encoder.encode(body)
            } catch {
                throw APIError.networkError(error)
            }
        }

        // Perform request
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }

        // Validate response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        // Handle HTTP status codes
        switch httpResponse.statusCode {
        case 200...299:
            // Success - decode response
            if T.self == EmptyResponse.self {
                // For DELETE requests that don't return data
                return EmptyResponse() as! T
            }

            do {
                let decoded = try decoder.decode(T.self, from: data)
                return decoded
            } catch {
                print("Decoding error: \(error)")
                print("Response data: \(String(data: data, encoding: .utf8) ?? "Unable to convert data to string")")
                throw APIError.decodingError(error)
            }

        case 401:
            // Unauthorized - token expired or invalid
            throw APIError.unauthorized

        case 400...499:
            // Client error
            let errorMessage = try? decoder.decode(ErrorResponse.self, from: data)
            throw APIError.serverError(httpResponse.statusCode, errorMessage?.message)

        case 500...599:
            // Server error
            let errorMessage = try? decoder.decode(ErrorResponse.self, from: data)
            throw APIError.serverError(httpResponse.statusCode, errorMessage?.message)

        default:
            throw APIError.serverError(httpResponse.statusCode, nil)
        }
    }
}

// MARK: - Helper Types

private struct EmptyResponse: Codable {}

private struct ErrorResponse: Codable {
    let message: String
    let detail: String?
}
