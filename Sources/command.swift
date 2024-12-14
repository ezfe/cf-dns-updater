import Foundation
import ArgumentParser

@main
struct CfDnsUpdater: AsyncParsableCommand {
    @Option
    var authEmail: String
    @Option
    var apiToken: String
    @Option
    var zoneId: String
    @Option
    var recordName: String

    func run() async throws {
        let config = CloudflareConfig(zoneIdentifier: zoneId,
                                      authEmail: authEmail,
                                      apiToken: apiToken,
                                      recordName: recordName)
        let cf = CloudflareAPI(config: config)

        try await update(type: .v4, cf: cf)
        try await update(type: .v6, cf: cf)
    }
}
