//
//  cf_api.swift
//  cf-dns-updater
//
//  Created by Ezekiel Elin on 12/13/24.
//

import Foundation

struct CloudflareConfig {
    let zoneIdentifier: String
    let authEmail: String
    let apiToken: String
    let recordName: String
}

// Auto-generated
struct DNSRecordsResponse: Decodable {
    let result: [DNSRecord]
    let success: Bool
    let errors: [String]
    let messages: [String]
}

struct DNSUpdateResponse: Decodable {
    let result: DNSRecord
    let success: Bool
    let errors: [String]
    let messages: [String]
}

struct DNSRecord: Decodable {
    let id: String
    let zoneId: String
    let zoneName: String
    let name: String
    let type: String
    let content: String
    let proxied: Bool
    let ttl: Int
}

enum CFError: Error {
    case urlError
    case responseError(URLResponse)
    case httpStatusError(Int)
    case decodeError(Error)
}

class CloudflareAPI {
    private(set) var config: CloudflareConfig

    init(config: CloudflareConfig) {
        self.config = config
    }

    func checkDNSRecord(type: IPType) async throws -> DNSRecordsResponse {
        var components = URLComponents(string: "https://api.cloudflare.com/client/v4/zones/\(config.zoneIdentifier)/dns_records")!
        components.queryItems = [
            URLQueryItem(name: "type", value: type.dns),
            URLQueryItem(name: "name", value: config.recordName)
        ]

        guard let url = components.url else {
            throw CFError.urlError
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(config.authEmail, forHTTPHeaderField: "X-Auth-Email")
        request.addValue("Bearer \(config.apiToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CFError.responseError(response)
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw CFError.httpStatusError(httpResponse.statusCode)
        }

        let jsonDecoder = JSONDecoder()
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        do {
            return try jsonDecoder.decode(DNSRecordsResponse.self, from: data)
        } catch let error {
            throw CFError.decodeError(error)
        }
    }

    func updateDNS(record: DNSRecord, ip: String) async throws -> DNSUpdateResponse {
        let url = URL(string: "https://api.cloudflare.com/client/v4/zones/\(config.zoneIdentifier)/dns_records/\(record.id)")!

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.addValue(config.authEmail, forHTTPHeaderField: "X-Auth-Email")
        request.addValue("Bearer \(config.apiToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let updateData: [String: Any] = [
            "type": record.type,
            "name": record.name,
            "content": ip,
            "ttl": record.ttl,
            "proxied": record.proxied
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: updateData)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CFError.responseError(response)
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw CFError.httpStatusError(httpResponse.statusCode)
        }

        let jsonDecoder = JSONDecoder()
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        do {
            return try jsonDecoder.decode(DNSUpdateResponse.self, from: data)
        } catch let error {
            throw CFError.decodeError(error)
        }
    }
}
