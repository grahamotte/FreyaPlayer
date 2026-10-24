import SwiftUI

struct PlexSetupContent: View {
    @ObservedObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingPlexNotice = false

    var body: some View {
        Form {
            Section {
                switch model.connectionState {
                case .checking, .savedConnectionFailed:
                    ProgressView("Checking saved Plex connection...")

                case .signedOut(let message):
                    Text(message)
                        .foregroundStyle(AppTheme.secondaryText)
                        .tvOSFocusableRow()

                case .connecting(let message):
                    if let code = model.plexLinkCode {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                            Text("Visit plex.tv/link in a browser and enter this code")
                                .foregroundStyle(AppTheme.secondaryText)

                            Text(code)
                                .font(.largeTitle.weight(.bold).monospaced())
                                .userSelectableText()
                        }
                        .tvOSFocusableRow()
                    }

                    Text(message)
                        .foregroundStyle(AppTheme.secondaryText)

                case .failed(let message):
                    Text(message)
                        .foregroundStyle(AppTheme.secondaryText)
                        .tvOSFocusableRow()

                case .connected:
                    ProgressView("Loading your server...")
                }
            }

            switch model.connectionState {
            case .signedOut:
                Section {
                    Button("Connect With Plex") {
                        model.startPlexLogin()
                    }
                }

            case .failed:
                Section {
                    Button("Try Again") {
                        model.startPlexLogin()
                    }
                }

            default:
                EmptyView()
            }
        }
        .readableFormWidth()
        .formBackdrop(.brand)
        .navigationTitle("Connect to Plex")
        .task {
            showingPlexNotice = true
        }
        .alert("Before You Use Plex", isPresented: $showingPlexNotice) {
            Button("I Understand, Continue") {
                model.preparePlexSetup()
            }

            Button("Cancel", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("Plex depends on plex.tv services for sign-in and server discovery, so using Plex means communicating to more than your own server.\n\nPlex may record login, connection, and watch history activity. Freya Player is committed to never tracking you, but we have no control or insight into what Plex collects while acting between this app and your server.\n\nIf Jellyfin is an option for you, we strongly recommend switching to it.")
        }
        .onDisappear {
            model.cancelPlexSetup()
        }
    }
}
