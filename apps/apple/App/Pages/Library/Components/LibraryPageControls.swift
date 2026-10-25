import SwiftUI

struct LibraryPageFilterMenu: View {
    let filter: LibraryPageFilter
    let onChange: (LibraryPageFilter) -> Void

    var body: some View {
        Menu {
            Picker("Show", selection: Binding(get: { filter }, set: onChange)) {
                ForEach(LibraryPageFilter.allCases, id: \.self) { candidate in
                    Text(candidate.title)
                }
            }
            .pickerStyle(.inline)
        } label: {
            Label(
                "Filter",
                systemImage: filter == .all ? "line.3.horizontal.decrease" : "line.3.horizontal.decrease.circle.fill"
            )
        }
        .accessibilityValue(filter.title)
    }
}

struct LibraryPageSortMenu: View {
    let sort: LibraryPageSort
    let order: LibraryPageSortOrder
    let onSortChange: (LibraryPageSort) -> Void
    let onSortOrderChange: (LibraryPageSortOrder) -> Void

    var body: some View {
        Menu {
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
            Label("Sort", systemImage: "arrow.up.arrow.down")
        }
        .accessibilityValue("\(sort.title), \(order.title)")
    }
}
