import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: ClipboardStore
    let onItemActivated: (ClipboardItem) -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                TextField("Search clipboard history", text: $store.searchText)
                    .textFieldStyle(.roundedBorder)
                Button("Clear Unpinned") {
                    store.clearUnpinned()
                }
            }

            List {
                ForEach(store.filteredItems) { item in
                    ClipboardRow(item: item, onItemActivated: onItemActivated)
                        .environmentObject(store)
                }
            }
            .listStyle(.inset)
        }
        .padding(16)
    }
}

private struct ClipboardRow: View {
    @EnvironmentObject private var store: ClipboardStore
    let item: ClipboardItem
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
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
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
                    .lineLimit(3)
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
                .buttonStyle(.borderedProminent)

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
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            onItemActivated(item)
        }
    }
}
