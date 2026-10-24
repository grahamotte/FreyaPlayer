import SwiftUI

struct LibraryPageOptionsMenu: View {
    let filter: LibraryPageFilter
    let sort: LibraryPageSort
    let order: LibraryPageSortOrder
    let onFilterChange: (LibraryPageFilter) -> Void
    let onSortChange: (LibraryPageSort) -> Void
    let onSortOrderChange: (LibraryPageSortOrder) -> Void

    var body: some View {
        Menu {
            Picker("Show", selection: Binding(get: { filter }, set: onFilterChange)) {
                ForEach(LibraryPageFilter.allCases, id: \.self) { candidate in
                    Text(candidate.title)
                }
            }
            .pickerStyle(.inline)

            Picker("Sort By", selection: Binding(get: { sort }, set: onSortChange)) {
                ForEach(LibraryPageSort.allCases, id: \.self) { candidate in
                    Text(candidate.title)
                }
            }
            .pickerStyle(.inline)

            Picker("Order", selection: Binding(get: { order }, set: onSortOrderChange)) {
                ForEach(LibraryPageSortOrder.allCases, id: \.self) { candidate in
                    Text(candidate.title)
                }
            }
            .pickerStyle(.inline)
        } label: {
            Label(
                "Filter and Sort",
                systemImage: filter == .all ? "line.3.horizontal.decrease" : "line.3.horizontal.decrease.circle.fill"
            )
        }
    }
}
