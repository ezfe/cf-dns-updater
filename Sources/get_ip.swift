//
//  get_ip.swift
//  cf-dns-updater
//
//  Created by Ezekiel Elin on 12/13/24.
//

import Foundation

enum IPType: String {
    case v4 = "v4"
    case v6 = "v6"

    var dns: String {
        return switch self {
            case .v4: "A"
            case .v6: "AAAA"
        }
    }

    var subdomain: String {
        return switch self {
            case .v4: "ipv4"
            case .v6: "ipv6"
        }
    }
}

func getIp(type: IPType) async throws -> String {
    let url = URL(string: "https://\(type.subdomain).icanhazip.com")!
    let (data, response) = try await URLSession.shared.data(from: url)

    guard let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode),
          let ipAddress = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) else {
        throw URLError(.badServerResponse)
    }

    return ipAddress
}
