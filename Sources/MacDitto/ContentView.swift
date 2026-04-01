import AppKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: ClipboardStore
    @FocusState private var searchFocused: Bool
    @State private var selectedItemID: ClipboardItem.ID?

    let onItemActivated: (ClipboardItem) -> Void
    let onDismiss: () -> Void

    private var selectedItem: ClipboardItem? {
        guard let selectedItemID else { return store.filteredItems.first }
        return store.filteredItems.first(where: { $0.id == selectedItemID }) ?? store.filteredItems.first
    }

    var body: some View {
        VStack(spacing: 14) {
            topBar
            listView
            footer
        }
        .padding(16)
        .frame(minWidth: 820, minHeight: 560)
        .onAppear {
            refreshSelection()
            searchFocused = true
        }
        .onChange(of: store.filteredItems.map(\.id)) { _ in
            refreshSelection()
        }
        .onExitCommand {
            onDismiss()
        }
        .background(
            Button("Paste Selected") {
                activateSelectedItem()
            }
            .keyboardShortcut(.defaultAction)
            .hidden()
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
            }

            Spacer()
        }
    }

    private var listView: some View {
        List(selection: $selectedItemID) {
            ForEach(store.filteredItems) { item in
                ClipboardRow(
                    item: item,
                    isSelected: item.id == selectedItem?.id,
                    onItemActivated: onItemActivated
                )
                .environmentObject(store)
                .tag(item.id)
            }
        }
        .listStyle(.inset)
        .onMoveCommand(perform: moveSelection)
    }

    private var footer: some View {
        HStack {
            Text("Arrow keys move, Return pastes, Escape closes. Settings are in the menu bar.")
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

    private func moveSelection(_ direction: MoveCommandDirection) {
        guard !store.filteredItems.isEmpty else { return }

        let currentIndex = store.filteredItems.firstIndex(where: { $0.id == selectedItem?.id }) ?? 0
        let nextIndex: Int

        switch direction {
        case .down:
            nextIndex = min(currentIndex + 1, store.filteredItems.count - 1)
        case .up:
            nextIndex = max(currentIndex - 1, 0)
        default:
            return
        }

        selectedItemID = store.filteredItems[nextIndex].id
    }
}

private struct ClipboardRow: View {
    @EnvironmentObject private var store: ClipboardStore
    let item: ClipboardItem
    let isSelected: Bool
    let onItemActivated: (ClipboardItem) -> Void

    private var timestamp: String {
        item.createdAt.formatted(date: .abbreviated, time: .shortened)
    }

    private var kindLabel: String {
        switch item.kind {
        case .text:
            return "TEXT"
        case .url:
            return "URL"
        case .fileReference:
            return "FILE"
        case .html:
            return "HTML"
        case .image:
            return "IMAGE"
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            previewPane

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    if item.pinned {
                        Text("PINNED")
                            .font(.caption2.monospaced())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.yellow.opacity(0.25))
                            .cornerRadius(4)
                    }
                    Text(kindLabel)
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                    Text(timestamp)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Text(item.value)
                    .font(.system(size: 13))
                    .textSelection(.enabled)
                    .lineLimit(item.kind == .image ? 1 : 3)
            }

            Spacer()

            HStack(spacing: 8) {
                Button(item.pinned ? "Unpin" : "Pin") {
                    store.togglePin(item)
                }
                .buttonStyle(.bordered)

                Button("Copy") {
                    store.copyToClipboard(item)
                }
                .buttonStyle(.bordered)

                Button("Paste") {
                    onItemActivated(item)
                }
                .buttonStyle(.borderedProminent)

                Button("Delete", role: .destructive) {
                    store.delete(item)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .background(isSelected ? Color.accentColor.opacity(0.12) : Color.clear)
        .cornerRadius(8)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            onItemActivated(item)
        }
    }

    @ViewBuilder
    private var previewPane: some View {
        switch item.kind {
        case .image:
            if let payload = item.payload, let nsImage = NSImage(data: payload) {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                    )
            } else {
                previewBadge(symbol: "photo")
            }
        case .html:
            previewBadge(symbol: "chevron.left.forwardslash.chevron.right")
        case .url:
            previewBadge(symbol: "link")
        case .fileReference:
            previewBadge(symbol: "doc")
        case .text:
            previewBadge(symbol: "text.alignleft")
        }
    }

    private func previewBadge(symbol: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.accentColor.opacity(0.12))
            Image(systemName: symbol)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color.accentColor)
        }
        .frame(width: 72, height: 72)
    }
}
