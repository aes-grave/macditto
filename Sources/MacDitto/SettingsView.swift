import AppKit
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Settings")
                .font(.title2.weight(.semibold))

            VStack(alignment: .leading, spacing: 12) {
                Text("Hotkey")
                    .font(.headline)

                HStack(spacing: 12) {
                    Text("Modifier")
                        .foregroundStyle(.secondary)
                        .frame(width: 70, alignment: .leading)
                    PopupButtonRepresentable(
                        items: HotkeyModifierPreset.allCases.map(\.displayName),
                        selectedIndex: modifierIndexBinding
                    )
                    .frame(width: 160, height: 28)
                    Spacer()
                }

                HStack(spacing: 12) {
                    Text("Key")
                        .foregroundStyle(.secondary)
                        .frame(width: 70, alignment: .leading)
                    PopupButtonRepresentable(
                        items: HotkeyOption.all.map(\.key),
                        selectedIndex: keyIndexBinding
                    )
                    .frame(width: 90, height: 28)
                    Spacer()
                }

                Text("Current shortcut: \(settings.hotkeyDisplayName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Startup")
                    .font(.headline)

                Toggle("Launch at Login", isOn: launchAtLoginBinding)
                    .toggleStyle(.switch)

                if let error = settings.launchAtLoginError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Spacer()
        }
        .padding(20)
        .frame(width: 360, height: 230)
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { settings.launchAtLoginEnabled },
            set: { settings.setLaunchAtLoginEnabled($0) }
        )
    }

    private var modifierBinding: Binding<HotkeyModifierPreset> {
        Binding(
            get: { settings.hotkey.modifierPreset },
            set: { settings.updateHotkeyModifier($0) }
        )
    }

    private var keyBinding: Binding<HotkeyOption> {
        Binding(
            get: { settings.hotkeyOption },
            set: { settings.updateHotkeyKey($0) }
        )
    }

    private var modifierIndexBinding: Binding<Int> {
        Binding(
            get: {
                HotkeyModifierPreset.allCases.firstIndex(of: settings.hotkey.modifierPreset) ?? 0
            },
            set: { newValue in
                guard HotkeyModifierPreset.allCases.indices.contains(newValue) else { return }
                modifierBinding.wrappedValue = HotkeyModifierPreset.allCases[newValue]
            }
        )
    }

    private var keyIndexBinding: Binding<Int> {
        Binding(
            get: {
                HotkeyOption.all.firstIndex(of: settings.hotkeyOption) ?? 0
            },
            set: { newValue in
                guard HotkeyOption.all.indices.contains(newValue) else { return }
                keyBinding.wrappedValue = HotkeyOption.all[newValue]
            }
        )
    }
}

private struct PopupButtonRepresentable: NSViewRepresentable {
    let items: [String]
    @Binding var selectedIndex: Int

    func makeCoordinator() -> Coordinator {
        Coordinator(selectedIndex: $selectedIndex)
    }

    func makeNSView(context: Context) -> NSPopUpButton {
        let button = NSPopUpButton(frame: .zero, pullsDown: false)
        button.target = context.coordinator
        button.action = #selector(Coordinator.selectionChanged(_:))
        button.bezelStyle = .rounded
        button.setContentHuggingPriority(.defaultLow, for: .horizontal)
        update(button)
        return button
    }

    func updateNSView(_ nsView: NSPopUpButton, context: Context) {
        update(nsView)
    }

    private func update(_ button: NSPopUpButton) {
        if button.itemTitles != items {
            button.removeAllItems()
            button.addItems(withTitles: items)
        }

        if items.indices.contains(selectedIndex) {
            button.selectItem(at: selectedIndex)
        }
    }

    final class Coordinator: NSObject {
        @Binding private var selectedIndex: Int

        init(selectedIndex: Binding<Int>) {
            self._selectedIndex = selectedIndex
        }

        @objc func selectionChanged(_ sender: NSPopUpButton) {
            selectedIndex = sender.indexOfSelectedItem
        }
    }
}
