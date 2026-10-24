import SwiftUI

struct ServerManagementLibrariesSection: View {
    let libraries: [LibraryShelf]
    let onToggleVisibility: (Int, Bool) -> Void
    let onMoveLibrary: (Int, Int) -> Void

    var body: some View {
        Section("Libraries") {
            ForEach(Array(libraries.enumerated()), id: \.element.id) { index, library in
                ServerManagementLibraryRow(
                    title: library.title,
                    isHidden: library.isHidden,
                    canMoveUp: index > 0,
                    canMoveDown: index < libraries.count - 1,
                    onToggleVisibility: {
                        onToggleVisibility(index, !library.isHidden)
                    },
                    onMoveUp: {
                        onMoveLibrary(index, -1)
                    },
                    onMoveDown: {
                        onMoveLibrary(index, 1)
                    }
                )
            }
        }
    }
}

private struct ServerManagementLibraryRow: View {
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
                .strikethrough(isHidden, color: AppTheme.secondaryText)
                .foregroundStyle(isHidden ? AppTheme.secondaryText : AppTheme.primaryText)

            Spacer(minLength: 0)

            rowButton("arrow.up", label: "Move \(title) Up", action: onMoveUp)
                .disabled(!canMoveUp)

            rowButton("arrow.down", label: "Move \(title) Down", action: onMoveDown)
                .disabled(!canMoveDown)

            rowButton(isHidden ? "eye.slash" : "eye", label: isHidden ? "Show \(title)" : "Hide \(title)", action: onToggleVisibility)
        }
    }

    private func rowButton(_ systemName: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .accessibilityLabel(label)
    }
}
