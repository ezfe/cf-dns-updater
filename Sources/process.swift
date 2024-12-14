//
//  process.swift
//  cf-dns-updater
//
//  Created by Ezekiel Elin on 12/14/24.
//

import Foundation

func update(type: IPType, cf: CloudflareAPI) async throws {
    print("Processing \(type.dns) record")

    let ip = try await getIp(type: type)

    print("\(type.rawValue) IP address is \(ip)")

    let response = try await cf.checkDNSRecord(type: type)

    guard let record = response.result.first else {
        print("No existing record for \(cf.config.recordName)")
        return
    }

    guard record.content != ip else {
        print("\(record.type) record for \(record.name) already points to \(ip)")
        return
    }

    let result = try await cf.updateDNS(record: record, ip: ip)

    if result.success {
        print("\(record.type) record for \(record.name) now points to \(record.content)")
    } else {
        print("\(record.type) record for \(record.name) update failed")
    }
}
