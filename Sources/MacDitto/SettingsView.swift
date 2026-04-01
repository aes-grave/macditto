import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        Form {
            Section("Hotkey") {
                LabeledContent("Modifier") {
                    Menu(settings.hotkey.modifierPreset.displayName) {
                        ForEach(HotkeyModifierPreset.allCases) { preset in
                            Button(preset.displayName) {
                                settings.updateHotkeyModifier(preset)
                            }
                        }
                    }
                    .frame(width: 160, alignment: .leading)
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                }

                LabeledContent("Key") {
                    Menu(settings.hotkeyOption.key) {
                        ForEach(HotkeyOption.all) { option in
                            Button(option.key) {
                                settings.updateHotkeyKey(option)
                            }
                        }
                    }
                    .frame(width: 100, alignment: .leading)
                    .menuStyle(.borderlessButton)
                    .fixedSize()
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

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { settings.launchAtLoginEnabled },
            set: { settings.setLaunchAtLoginEnabled($0) }
        )
    }
}
