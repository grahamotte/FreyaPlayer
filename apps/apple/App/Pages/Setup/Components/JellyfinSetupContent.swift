import SwiftUI

struct JellyfinSetupContent: View {
    @ObservedObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var serverProtocol = "https"
    @State private var address = ""
    @State private var port = "443"
    @State private var username = ""
    @State private var password = ""
    @FocusState private var focusedField: Field?

    var body: some View {
        Group {
            if case .connecting(let message) = model.connectionState {
                ProgressView(message)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                form
            }
        }
        .background(AppBackground())
        .task {
            model.prepareJellyfinSetup()
        }
    }

    private var form: some View {
        VStack(spacing: AppTheme.Spacing.xLarge) {
            Spacer()

            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                MediaProviderLabel(providerID: .jellyfin)
                    .font(PlatformMetadata.sectionTitleFont)

                serverAddressLayout {
                    setupTextField(
                        "Protocol",
                        text: $serverProtocol,
                        placeholder: "https",
                        field: .protocol
                    )
                    .frame(width: usesCompactLayout ? nil : shortFieldWidth)

                    setupTextField(
                        "Address",
                        text: $address,
                        placeholder: "64.23.154.109",
                        field: .address
                    )
                    .frame(maxWidth: .infinity)

                    setupTextField(
                        "Port",
                        text: $port,
                        placeholder: serverProtocol == "https" ? "443" : "8096",
                        field: .port
                    )
                    .frame(width: usesCompactLayout ? nil : shortFieldWidth)
                }

                setupTextField(
                    "Username",
                    text: $username,
                    placeholder: "Username",
                    field: .username
                )

                setupTextField(
                    "Password",
                    text: $password,
                    placeholder: "Password",
                    field: .password
                )

                if case .failed(let message) = model.connectionState {
                    Text(message)
                        .foregroundStyle(AppTheme.secondaryText)
                }

                HStack(spacing: AppTheme.Spacing.medium) {
                    Button("Connect") {
                        if let serverURL {
                            model.connectJellyfin(
                                serverURL: serverURL,
                                username: username,
                                password: password
                            )
                        }
                    }
                    .buttonStyle(MediaGlassButtonStyle())
                    .focused($focusedField, equals: .connect)
                    .disabled(serverURL == nil || username.isEmpty || password.isEmpty)

                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(MediaGlassButtonStyle())
                }
            }
            .frame(maxWidth: 720, alignment: .leading)
            .padding(PlatformMetadata.panelPadding)
            .background(PanelBackground())

            Spacer()
        }
        .padding(PlatformMetadata.pageGutter)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: serverProtocol) { _, newValue in
            applyDefaultPort(for: newValue)
        }
    }

    private var serverURL: String? {
        let serverProtocol = serverProtocol.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let address = address.trimmingCharacters(in: .whitespacesAndNewlines)
        let port = port.trimmingCharacters(in: .whitespacesAndNewlines)
        guard
            serverProtocol == "http" || serverProtocol == "https",
            !address.isEmpty,
            let port = Int(port),
            1...65_535 ~= port
        else { return nil }
        return "\(serverProtocol)://\(address):\(port)"
    }

    private var usesCompactLayout: Bool {
        horizontalSizeClass == .compact
    }

    private var fieldLabelFont: Font {
        PlatformMetadata.labelFont.weight(.semibold)
    }

    private var shortFieldWidth: CGFloat {
        PlatformMetadata.isTV ? 160 : 120
    }

    private func serverAddressLayout<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        let layout = usesCompactLayout
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: AppTheme.Spacing.medium))
            : AnyLayout(HStackLayout(alignment: .bottom, spacing: AppTheme.Spacing.medium))
        return layout {
            content()
        }
    }

    private func setupField<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
            Text(title)
                .font(fieldLabelFont)
                .foregroundStyle(AppTheme.secondaryText)

            content()
        }
    }

    private func setupTextField(
        _ title: String,
        text: Binding<String>,
        placeholder: String,
        field: Field
    ) -> some View {
        let isFocused = focusedField == field
        let prompt = Text(placeholder)
            .foregroundStyle(AppTheme.secondaryText)

        return setupField(title) {
            TextField(title, text: text, prompt: prompt)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($focusedField, equals: field)
                .submitLabel(field == .password ? .done : .next)
                .onSubmit { advance(from: field) }
                .textFieldStyle(.plain)
                .font(PlatformMetadata.labelFont)
                .foregroundStyle(AppTheme.primaryText)
                .padding(.horizontal, AppTheme.Spacing.medium)
                .frame(maxWidth: .infinity, minHeight: fieldHeight, maxHeight: fieldHeight, alignment: .leading)
                .background(AppTheme.surfaceFill, in: Capsule())
                .overlay {
                    Capsule().stroke(
                        isFocused ? AppTheme.focusStroke : AppTheme.surfaceBorder,
                        lineWidth: isFocused ? 2 : 1
                    )
                }
        }
    }

    private var fieldHeight: CGFloat {
        PlatformMetadata.isTV ? 80 : 44
    }

    private func advance(from field: Field) {
        switch field {
        case .protocol: focusedField = .address
        case .address: focusedField = .port
        case .port: focusedField = .username
        case .username: focusedField = .password
        case .password, .connect: focusedField = .connect
        }
    }

    private func applyDefaultPort(for serverProtocol: String) {
        switch serverProtocol.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "https": port = "443"
        case "http": port = "8096"
        default: break
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
}
