import SwiftUI

struct JellyfinSetupContent: View {
    @ObservedObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
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
            } else {
                form
            }
        }
        .padding(PlatformMetadata.pageGutter)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppBackground())
        .task {
            model.prepareJellyfinSetup()
        }
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            MediaProviderLabel(providerID: .jellyfin)
                .font(PlatformMetadata.sectionTitleFont)

            serverFields

            setupField("Username") {
                setupTextField("Username", text: $username, placeholder: "Username", field: .username)
                    .textContentType(.username)
            }

            setupField("Password") {
                setupTextField("Password", text: $password, placeholder: "Password", field: .password)
                    .textContentType(.password)
            }

            if case .failed(let message) = model.connectionState {
                Text(message)
                    .foregroundStyle(AppTheme.secondaryText)
            }

            HStack(spacing: AppTheme.Spacing.medium) {
                Button("Connect") {
                    connect()
                }
                .buttonStyle(MediaGlassButtonStyle())
                .focused($focusedField, equals: .connect)
                .disabled(!canConnect)

                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(MediaGlassButtonStyle())
            }
        }
        .frame(maxWidth: formWidth, alignment: .leading)
        .padding(PlatformMetadata.panelPadding)
        .background(PanelBackground())
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

    @ViewBuilder
    private var serverFields: some View {
        if usesCompactLayout {
            setupField("Protocol") {
                protocolPicker
            }

            setupField("Address") {
                addressField
            }

            setupField("Port") {
                portField
            }
        } else {
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

                    addressField

                    portField
                        .frame(width: portFieldWidth)
                }
            }
        }
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

    private var addressField: some View {
        setupTextField("Address", text: $address, placeholder: "jellyfin.example.com", field: .address)
            .keyboardType(.URL)
    }

    private var portField: some View {
        setupTextField("Port", text: $port, placeholder: serverProtocol.defaultPort, field: .port)
            .keyboardType(.numberPad)
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

    private var usesCompactLayout: Bool {
        horizontalSizeClass == .compact
    }

    private var formWidth: CGFloat {
        PlatformMetadata.isTV ? 1000 : 720
    }

    private var portFieldWidth: CGFloat {
        PlatformMetadata.isTV ? 200 : 100
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

    private func fieldLabel(_ title: String) -> some View {
        Text(title)
            .font(PlatformMetadata.labelFont.weight(.semibold))
            .foregroundStyle(AppTheme.secondaryText)
    }

    private func setupField<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
            fieldLabel(title)

            content()
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
        .foregroundStyle(Color.primary)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .focused($focusedField, equals: field)
        .submitLabel(nextField(after: field) == .connect ? .done : .next)
        .onSubmit {
            focusAfterEditing = nextField(after: field)
            focusedField = focusAfterEditing
        }
        .setupTextFieldStyle(isFocused: focusedField == field)
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

private extension View {
    @ViewBuilder
    func setupTextFieldStyle(isFocused: Bool) -> some View {
        #if os(tvOS)
            self
        #else
            textFieldStyle(.plain)
                .padding(.horizontal, AppTheme.Spacing.medium)
                .frame(minHeight: 48)
                .background(AppTheme.glassFill, in: Capsule())
                .overlay {
                    Capsule()
                        .strokeBorder(isFocused ? AppTheme.focusStroke : AppTheme.glassStroke, lineWidth: 1)
                }
        #endif
    }
}
