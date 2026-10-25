import SwiftUI

struct MediaPlayAllButton: View {
    @ObservedObject var model: AppModel
    let items: [MediaItem]
    var isProminent = false

    @StateObject private var session: MediaPlaybackSession
    @FocusState private var isPlayFocused: Bool

    init(model: AppModel, items: [MediaItem], isProminent: Bool = false) {
        self.model = model
        self.items = items
        self.isProminent = isProminent
        _session = StateObject(wrappedValue: MediaPlaybackSession(model: model))
    }

    var body: some View {
        Menu {
            Button("In Order") {
                session.play(items)
            }
            Button("Shuffle") {
                session.play(items, shuffled: true)
            }
        } label: {
            if session.isLoading {
                ProgressView()
            } else {
                if isProminent {
                    Label("Play All", systemImage: "play.fill")
                        .glassPillLabel()
                        .foregroundStyle(AppTheme.onAccent)
                } else {
                    Label("Play All", systemImage: "play.fill")
                        .glassPillLabel()
                }
            }
        }
        .menuStyle(.button)
        .playActionStyle(isProminent: isProminent)
        .focused($isPlayFocused)
        .disabled(model.isOffline || session.isLoading || !items.contains { $0.playbackID != nil })
        .fixedSize(horizontal: true, vertical: false)
        .task {
            guard isProminent else { return }
            isPlayFocused = true
        }
    }
}
