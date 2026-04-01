import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: ClipboardStore
    @FocusState private var searchFocused: Bool
    @State private var selectedItemID: ClipboardItem.ID?
    @State private var historyFocusToken = 0

    let onItemActivated: (ClipboardItem) -> Void
    let onDismiss: () -> Void

    private var selectedItem: ClipboardItem? {
        guard let selectedItemID else { return store.filteredItems.first }
        return store.filteredItems.first(where: { $0.id == selectedItemID }) ?? store.filteredItems.first
    }

    var body: some View {
        VStack(spacing: 14) {
            topBar
            historyView
            actionBar
            footer
        }
        .padding(16)
        .frame(minWidth: 820, minHeight: 560)
        .onAppear {
            refreshSelection()
            historyFocusToken += 1
        }
        .onChange(of: store.filteredItems.map(\.id)) { _ in
            refreshSelection()
        }
        .onExitCommand {
            onDismiss()
        }
        .background(
            Group {
                Button("Paste Selected") {
                    activateSelectedItem()
                }
                .keyboardShortcut(.defaultAction)
                .hidden()

                Button("Focus Search") {
                    searchFocused = true
                }
                .keyboardShortcut("f", modifiers: [.command])
                .hidden()
            }
        )
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            TextField("Search clipboard history", text: $store.searchText)
                .textFieldStyle(.roundedBorder)
                .focused($searchFocused)
                .onSubmit {
                    activateSelectedItem()
                }

            Button("Clear Unpinned") {
                store.clearUnpinned()
                refreshSelection()
                historyFocusToken += 1
            }

            Spacer()
        }
    }

    private var historyView: some View {
        ClipboardTableView(
            items: store.filteredItems,
            selectedItemID: $selectedItemID,
            onActivateItem: onItemActivated,
            onDismiss: onDismiss,
            focusToken: historyFocusToken
        )
    }

    private var actionBar: some View {
        HStack(spacing: 10) {
            Button(selectedItem?.pinned == true ? "Unpin" : "Pin") {
                guard let selectedItem else { return }
                store.togglePin(selectedItem)
            }
            .buttonStyle(.bordered)
            .disabled(selectedItem == nil)

            Button("Copy") {
                guard let selectedItem else { return }
                store.copyToClipboard(selectedItem)
            }
            .buttonStyle(.bordered)
            .disabled(selectedItem == nil)

            Button("Paste") {
                activateSelectedItem()
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedItem == nil)

            Button("Delete", role: .destructive) {
                guard let selectedItem else { return }
                let deletedID = selectedItem.id
                store.delete(selectedItem)
                if selectedItemID == deletedID {
                    selectedItemID = nil
                    refreshSelection()
                    historyFocusToken += 1
                }
            }
            .buttonStyle(.bordered)
            .disabled(selectedItem == nil)

            Spacer()
        }
    }

    private var footer: some View {
        HStack {
            Text("Arrow keys move, Return pastes, Escape closes. Cmd+F focuses search.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(store.filteredItems.count) items")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func refreshSelection() {
        guard !store.filteredItems.isEmpty else {
            selectedItemID = nil
            return
        }

        if let selectedItemID,
           store.filteredItems.contains(where: { $0.id == selectedItemID }) {
            return
        }

        selectedItemID = store.filteredItems.first?.id
    }

    private func activateSelectedItem() {
        guard let selectedItem else { return }
        onItemActivated(selectedItem)
    }
}
