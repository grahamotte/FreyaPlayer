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
            } else if PlatformMetadata.isTV {
                tvForm
            } else {
                form
            }
        }
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
        .navigationTitle("Connect to Jellyfin")
        .task {
            model.prepareJellyfinSetup()
        }
    }

    private var form: some View {
        Form {
            Section("Server") {
                protocolPicker

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
        .formBackdrop(.brand)
    }

    private var tvForm: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
            Grid(
                alignment: .leading,
                horizontalSpacing: AppTheme.Spacing.medium,
                verticalSpacing: AppTheme.Spacing.xSmall
            ) {
                GridRow {
                    fieldLabel("Protocol")
                    fieldLabel("Address")
                    fieldLabel("Port")
                }

                GridRow {
                    protocolPicker
                        .fixedSize()

                    setupTextField("Address", text: $address, placeholder: "jellyfin.example.com", field: .address)
                        .keyboardType(.URL)

                    setupTextField("Port", text: $port, placeholder: serverProtocol.defaultPort, field: .port)
                        .keyboardType(.numberPad)
                        .frame(width: 200)
                }
            }

            labeledField("Username") {
                setupTextField("Username", text: $username, placeholder: "Username", field: .username)
                    .textContentType(.username)
            }

            labeledField("Password") {
                setupTextField("Password", text: $password, placeholder: "Password", field: .password)
                    .textContentType(.password)
            }

            if case .failed(let message) = model.connectionState {
                Text(message)
                    .foregroundStyle(AppTheme.secondaryText)
            }

            Button {
                connect()
            } label: {
                Text("Connect")
                    .foregroundStyle(AppTheme.onAccent)
            }
            .playActionStyle()
            .focused($focusedField, equals: .connect)
            .disabled(!canConnect)
        }
        .frame(maxWidth: 1000, alignment: .leading)
        .padding(PlatformMetadata.pageGutter)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ArtworkLitBackground(url: nil, fallback: .brand))
    }

    private var protocolPicker: some View {
        Picker("Protocol", selection: $serverProtocol) {
            ForEach(ServerProtocol.allCases, id: \.self) { serverProtocol in
                Text(serverProtocol.title)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .focused($focusedField, equals: .protocol)
    }

    private func fieldLabel(_ title: String) -> some View {
        Text(title)
            .font(PlatformMetadata.labelFont.weight(.semibold))
            .foregroundStyle(AppTheme.secondaryText)
    }

    private func labeledField<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
            fieldLabel(title)
            content()
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
        let prompt = PlatformMetadata.isTV ? nil : Text(placeholder)
        return Group {
            if field == .password {
                SecureField(title, text: text, prompt: prompt)
            } else {
                TextField(title, text: text, prompt: prompt)
            }
        }
        .font(PlatformMetadata.isTV ? .headline : nil)
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
