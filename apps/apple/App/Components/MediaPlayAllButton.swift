import SwiftUI

struct MediaPlayAllButton: View {
    @ObservedObject var model: AppModel
    let items: [MediaItem]

    @StateObject private var session: MediaPlaybackSession
    @FocusState private var isPlayFocused: Bool

    init(model: AppModel, items: [MediaItem]) {
        self.model = model
        self.items = items
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
                Label("Play All", systemImage: "play.fill")
            }
        }
        .menuStyle(.button)
        .buttonStyle(.glass)
        .focused($isPlayFocused)
        .disabled(model.isOffline || session.isLoading || !items.contains { $0.playbackID != nil })
        .fixedSize(horizontal: true, vertical: false)
        .task {
            isPlayFocused = true
        }
    }
}
