import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        Form {
            Section("Hotkey") {
                Picker("Modifier", selection: modifierBinding) {
                    ForEach(HotkeyModifierPreset.allCases) { preset in
                        Text(preset.displayName).tag(preset)
                    }
                }

                Picker("Key", selection: keyBinding) {
                    ForEach(HotkeyOption.all) { option in
                        Text(option.key).tag(option)
                    }
                }

                Text("Current shortcut: \(settings.hotkeyDisplayName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Startup") {
                Toggle("Launch at Login", isOn: launchAtLoginBinding)

                if let error = settings.launchAtLoginError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .padding(20)
        .frame(width: 420, height: 240)
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

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { settings.launchAtLoginEnabled },
            set: { settings.setLaunchAtLoginEnabled($0) }
        )
    }
}
