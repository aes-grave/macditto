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
                    settingsPickerRow(title: "Modifier", width: 180) {
                        Picker("Modifier", selection: modifierBinding) {
                            ForEach(HotkeyModifierPreset.allCases) { preset in
                                Text(preset.displayName).tag(preset)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity)
                    }

                    settingsPickerRow(title: "Key", width: 110) {
                        Picker("Key", selection: keyBinding) {
                            ForEach(HotkeyOption.all) { option in
                                Text(option.key).tag(option)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity)
                    }
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
        .frame(width: 440, height: 260)
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

    private func settingsPickerRow<Content: View>(title: String, width: CGFloat, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            content()
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(NSColor.controlBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                )
        }
        .frame(width: width, alignment: .leading)
    }
}
