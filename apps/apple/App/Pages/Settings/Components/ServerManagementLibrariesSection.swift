import SwiftUI

struct ServerManagementLibrariesSection: View {
    let libraries: [LibraryShelf]
    let onToggleVisibility: (Int, Bool) -> Void
    let onMoveLibrary: (Int, Int) -> Void

    var body: some View {
        Section {
            if PlatformMetadata.isTV {
                ForEach(Array(libraries.enumerated()), id: \.element.id) { index, library in
                    TvLibraryRow(
                        title: library.title,
                        isHidden: library.isHidden,
                        canMoveUp: index > 0,
                        canMoveDown: index < libraries.count - 1,
                        onToggleVisibility: { onToggleVisibility(index, !library.isHidden) },
                        onMoveUp: { onMoveLibrary(index, -1) },
                        onMoveDown: { onMoveLibrary(index, 1) }
                    )
                }
            } else {
                ForEach(Array(libraries.enumerated()), id: \.element.id) { index, library in
                    Toggle(
                        library.title,
                        isOn: Binding(
                            get: { !library.isHidden },
                            set: { onToggleVisibility(index, !$0) }
                        )
                    )
                    .tint(.green)
                }
                .onMove { source, destination in
                    guard let index = source.first else { return }
                    let target = destination > index ? destination - 1 : destination
                    onMoveLibrary(index, target - index)
                }
            }
        } header: {
            Text("Libraries")
        } footer: {
            Text(PlatformMetadata.isTV ? "Hidden libraries don't appear on Home." : "Hidden libraries don't appear on Home. Choose Edit to reorder.")
        }
    }
}

private struct TvLibraryRow: View {
    let title: String
    let isHidden: Bool
    let canMoveUp: Bool
    let canMoveDown: Bool
    let onToggleVisibility: () -> Void
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void

    var body: some View {
        HStack(spacing: PlatformMetadata.controlSpacing) {
            Text(title)
                .lineLimit(1)
                .foregroundStyle(isHidden ? AppTheme.secondaryText : AppTheme.primaryText)

            Spacer(minLength: 0)

            Button(isHidden ? "Hidden" : "Shown", action: onToggleVisibility)
                .buttonStyle(.glass)
                .accessibilityLabel(isHidden ? "Show \(title)" : "Hide \(title)")

            Button(action: onMoveUp) {
                Label("Move \(title) Up", systemImage: "arrow.up")
            }
            .glassIconButton()
            .disabled(!canMoveUp)

            Button(action: onMoveDown) {
                Label("Move \(title) Down", systemImage: "arrow.down")
            }
            .glassIconButton()
            .disabled(!canMoveDown)
        }
    }
}
