import SwiftUI

struct ServerManagementServerSection: View {
    let server: ConnectedServer
    let onDeactivate: () -> Void

    var body: some View {
        Section("Server") {
            LabeledContent("Name", value: server.serverName)
            LabeledContent("Address", value: server.serverURL)
            LabeledContent("Provider", value: server.providerID.title)

            Button("Deactivate Server…", action: onDeactivate)
        }
    }
}
