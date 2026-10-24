import SwiftUI

struct JellyfinSetupContent: View {
    @ObservedObject var model: AppModel
    @State private var serverProtocol = ServerProtocol.https
    @State private var address = ""
    @State private var port = ServerProtocol.https.defaultPort
    @State private var username = ""
    @State private var password = ""
    @FocusState private var focusedField: Field?
    @State private var focusAfterEditing: Field?

    var body: some View {
        Group {
            if case .connecting(let message) = model.connectionState {
                ProgressView(message)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                form
            }
        }
        .navigationTitle("Connect to Jellyfin")
        .task {
            model.prepareJellyfinSetup()
        }
    }

    private var form: some View {
        Form {
            Section("Server") {
                Picker("Protocol", selection: $serverProtocol) {
                    ForEach(ServerProtocol.allCases, id: \.self) { serverProtocol in
                        Text(serverProtocol.title)
                    }
                }
                .pickerStyle(.segmented)
                .focused($focusedField, equals: .protocol)

                setupTextField("Address", text: $address, placeholder: "jellyfin.example.com", field: .address)
                    .keyboardType(.URL)

                setupTextField("Port", text: $port, placeholder: serverProtocol.defaultPort, field: .port)
                    .keyboardType(.numberPad)
            }

            Section("Account") {
                setupTextField("Username", text: $username, placeholder: "Username", field: .username)
                    .textContentType(.username)

                setupTextField("Password", text: $password, placeholder: "Password", field: .password)
                    .textContentType(.password)
            }

            Section {
                Button("Connect") {
                    connect()
                }
                .focused($focusedField, equals: .connect)
                .disabled(!canConnect)
            } footer: {
                if case .failed(let message) = model.connectionState {
                    Text(message)
                }
            }
        }
        .readableFormWidth()
        .defaultFocus($focusedField, canConnect ? .connect : .address)
        .onChange(of: serverProtocol) { _, serverProtocol in
            port = serverProtocol.defaultPort
        }
        .onChange(of: focusedField) { _, field in
            guard let target = focusAfterEditing else { return }
            focusAfterEditing = nil
            guard field != target else { return }
            Task {
                await Task.yield()
                focusedField = target
            }
        }
    }

    private var serverURL: String? {
        let address = address.trimmingCharacters(in: .whitespacesAndNewlines)
        let port = port.trimmingCharacters(in: .whitespacesAndNewlines)
        guard
            !address.isEmpty,
            let port = Int(port),
            1...65_535 ~= port
        else { return nil }
        return "\(serverProtocol.rawValue)://\(address):\(port)"
    }

    private var canConnect: Bool {
        serverURL != nil && !username.isEmpty && !password.isEmpty
    }

    private func connect() {
        guard let serverURL else { return }
        model.connectJellyfin(serverURL: serverURL, username: username, password: password)
    }

    private func nextField(after field: Field) -> Field {
        switch field {
        case .protocol: .address
        case .address: .port
        case .port: .username
        case .username: .password
        case .password, .connect: .connect
        }
    }

    private func setupTextField(
        _ title: String,
        text: Binding<String>,
        placeholder: String,
        field: Field
    ) -> some View {
        Group {
            if field == .password {
                SecureField(title, text: text, prompt: Text(placeholder))
            } else {
                TextField(title, text: text, prompt: Text(placeholder))
            }
        }
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .focused($focusedField, equals: field)
        .submitLabel(nextField(after: field) == .connect ? .done : .next)
        .onSubmit {
            focusAfterEditing = nextField(after: field)
            focusedField = focusAfterEditing
        }
    }

    private enum Field: Hashable {
        case `protocol`
        case address
        case port
        case username
        case password
        case connect
    }

    private enum ServerProtocol: String, CaseIterable {
        case https
        case http

        var title: String {
            rawValue.uppercased()
        }

        var defaultPort: String {
            switch self {
            case .https: "443"
            case .http: "8096"
            }
        }
    }
}
