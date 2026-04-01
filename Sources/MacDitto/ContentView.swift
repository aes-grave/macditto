import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: ClipboardStore
    @EnvironmentObject private var settings: AppSettings
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
            launchControls
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
        }
    }

    private var launchControls: some View {
        HStack(spacing: 14) {
            Picker("Shortcut", selection: hotkeyModifierBinding) {
                ForEach(HotkeyModifierPreset.allCases) { preset in
                    Text(preset.displayName).tag(preset)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 140)

            Picker("Key", selection: hotkeyKeyBinding) {
                ForEach(HotkeyOption.all) { option in
                    Text(option.key).tag(option)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 90)

            Toggle("Launch at Login", isOn: launchAtLoginBinding)
                .toggleStyle(.checkbox)

            if let error = settings.launchAtLoginError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .lineLimit(2)
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
            Text("Arrow keys move, Return pastes, Escape closes.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(store.filteredItems.count) items")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var hotkeyModifierBinding: Binding<HotkeyModifierPreset> {
        Binding(
            get: { settings.hotkey.modifierPreset },
            set: { settings.updateHotkeyModifier($0) }
        )
    }

    private var hotkeyKeyBinding: Binding<HotkeyOption> {
        Binding(
            get: { settings.hotkeyOption },
            set: { settings.updateHotkeyKey($0) }
        )
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { settings.launchAtLoginEnabled },
            set: { settings.setLaunchAtLoginEnabled($0) }
        )
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
}
