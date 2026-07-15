import SwiftData
import SwiftUI

struct ListsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CustomList.createdAt, order: .reverse) private var lists: [CustomList]
    @State private var isCreating = false

    var body: some View {
        MashhadBackground {
            Group {
                if lists.isEmpty {
                    EmptyStateView(
                        title: "lists_empty_title",
                        message: "lists_empty_message",
                        symbol: "square.stack.3d.up",
                        actionTitle: "lists_create",
                        action: { isCreating = true }
                    )
                } else {
                    List {
                        ForEach(lists) { list in
                            NavigationLink(destination: ListDetailView(list: list)) {
                                ListRow(list: list)
                            }
                            .listRowBackground(MashhadTheme.surface)
                        }
                        .onDelete(perform: delete)
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .padding(.horizontal, lists.isEmpty ? MashhadTheme.pagePadding : 0)
        }
        .navigationTitle("lists_title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("lists_create", systemImage: "plus") { isCreating = true }
                    .accessibilityLabel(Text("lists_create"))
            }
        }
        .sheet(isPresented: $isCreating) {
            NavigationStack { CreateListView() }
        }
    }

    private func delete(at offsets: IndexSet) {
        offsets.map { lists[$0] }.forEach(modelContext.delete)
    }
}

private struct ListRow: View {
    let list: CustomList

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "square.stack.3d.up.fill")
                .font(.title2)
                .foregroundStyle(MashhadTheme.accentSecondary)
                .frame(width: 42, height: 42)
                .background(MashhadTheme.surfaceElevated, in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 5) {
                Text(list.title)
                    .font(.headline)
                    .foregroundStyle(MashhadTheme.textPrimary)
                Text("\(list.items.count) \(String(localized: "lists_items"))")
                    .font(.caption)
                    .foregroundStyle(MashhadTheme.textSecondary)
            }
            Spacer()
        }
        .padding(.vertical, 6)
    }
}

private struct CreateListView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var title = ""
    @State private var description = ""
    @State private var visibility: CustomListVisibility = .private

    var body: some View {
        Form {
            Section {
                TextField("lists_new_title", text: $title)
                TextField("lists_description", text: $description, axis: .vertical)
                    .lineLimit(3...6)
            }
            Section {
                Picker("lists_visibility", selection: $visibility) {
                    Text("lists_private").tag(CustomListVisibility.private)
                    Text("lists_public").tag(CustomListVisibility.publicList)
                    Text("lists_unlisted").tag(CustomListVisibility.unlisted)
                }
            }
            Section {
                Button("lists_save") { save() }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .navigationTitle("lists_create")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("common_cancel") { dismiss() }
            }
        }
    }

    private func save() {
        let list = CustomList(title: title.trimmingCharacters(in: .whitespacesAndNewlines), description: description, visibility: visibility)
        modelContext.insert(list)
        try? modelContext.save()
        dismiss()
    }
}

struct ListPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CustomList.updatedAt, order: .reverse) private var lists: [CustomList]

    let media: MediaSummary

    var body: some View {
        List {
            if lists.isEmpty {
                ContentUnavailableView("lists_no_lists", systemImage: "square.stack.3d.up", description: Text("lists_no_lists_message"))
            } else {
                ForEach(lists) { list in
                    Button {
                        list.add(media: media)
                        try? modelContext.save()
                        dismiss()
                    } label: {
                        HStack {
                            Text(list.title)
                                .foregroundStyle(MashhadTheme.textPrimary)
                            Spacer()
                            if list.items.contains(where: { $0.id == "\(media.kind.rawValue)-\(media.id)" }) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(MashhadTheme.accent)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("lists_choose")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("common_cancel") { dismiss() }
            }
        }
    }
}

private struct ListDetailView: View {
    let list: CustomList

    var body: some View {
        MashhadBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(list.title)
                        .font(.largeTitle.bold())
                        .foregroundStyle(MashhadTheme.textPrimary)
                    if !list.listDescription.isEmpty {
                        Text(list.listDescription)
                            .foregroundStyle(MashhadTheme.textSecondary)
                    }
                    if list.items.isEmpty {
                        EmptyStateView(title: "lists_items_empty_title", message: "lists_items_empty_message", symbol: "film")
                    } else {
                        ForEach(list.items) { item in
                            HStack(spacing: 12) {
                                Image(systemName: item.kind == .movie ? "film" : "tv")
                                    .foregroundStyle(MashhadTheme.accent)
                                Text(item.title)
                                    .foregroundStyle(MashhadTheme.textPrimary)
                                Spacer()
                            }
                            .padding()
                            .background(MashhadTheme.surface, in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding(.horizontal, MashhadTheme.pagePadding)
                .padding(.vertical, 24)
            }
        }
        .navigationTitle("lists_title")
        .navigationBarTitleDisplayMode(.inline)
    }
}
