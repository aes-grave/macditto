import AppKit
import Foundation
import ServiceManagement

enum HotkeyModifierPreset: String, Codable, CaseIterable, Identifiable {
    case controlShift
    case commandShift
    case optionShift
    case controlOption

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .controlShift:
            return "Ctrl+Shift"
        case .commandShift:
            return "Cmd+Shift"
        case .optionShift:
            return "Option+Shift"
        case .controlOption:
            return "Ctrl+Option"
        }
    }

    var flags: NSEvent.ModifierFlags {
        switch self {
        case .controlShift:
            return [.control, .shift]
        case .commandShift:
            return [.command, .shift]
        case .optionShift:
            return [.option, .shift]
        case .controlOption:
            return [.control, .option]
        }
    }
}

struct HotkeyOption: Identifiable, Equatable, Hashable {
    let keyCode: UInt16
    let key: String

    var id: UInt16 { keyCode }

    static let all: [HotkeyOption] = [
        HotkeyOption(keyCode: 0, key: "A"),
        HotkeyOption(keyCode: 11, key: "B"),
        HotkeyOption(keyCode: 8, key: "C"),
        HotkeyOption(keyCode: 2, key: "D"),
        HotkeyOption(keyCode: 14, key: "E"),
        HotkeyOption(keyCode: 3, key: "F"),
        HotkeyOption(keyCode: 5, key: "G"),
        HotkeyOption(keyCode: 4, key: "H"),
        HotkeyOption(keyCode: 34, key: "I"),
        HotkeyOption(keyCode: 38, key: "J"),
        HotkeyOption(keyCode: 40, key: "K"),
        HotkeyOption(keyCode: 37, key: "L"),
        HotkeyOption(keyCode: 46, key: "M"),
        HotkeyOption(keyCode: 45, key: "N"),
        HotkeyOption(keyCode: 31, key: "O"),
        HotkeyOption(keyCode: 35, key: "P"),
        HotkeyOption(keyCode: 12, key: "Q"),
        HotkeyOption(keyCode: 15, key: "R"),
        HotkeyOption(keyCode: 1, key: "S"),
        HotkeyOption(keyCode: 17, key: "T"),
        HotkeyOption(keyCode: 32, key: "U"),
        HotkeyOption(keyCode: 9, key: "V"),
        HotkeyOption(keyCode: 13, key: "W"),
        HotkeyOption(keyCode: 7, key: "X"),
        HotkeyOption(keyCode: 16, key: "Y"),
        HotkeyOption(keyCode: 6, key: "Z")
    ]

    static func option(for keyCode: UInt16) -> HotkeyOption {
        all.first(where: { $0.keyCode == keyCode }) ?? HotkeyOption(keyCode: 9, key: "V")
    }
}

struct HotkeyConfiguration: Codable, Equatable {
    var modifierPreset: HotkeyModifierPreset
    var keyCode: UInt16

    static let `default` = HotkeyConfiguration(modifierPreset: .controlShift, keyCode: 9)
}

@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published private(set) var hotkey: HotkeyConfiguration
    @Published private(set) var launchAtLoginEnabled: Bool
    @Published var launchAtLoginError: String?

    private let defaults = UserDefaults.standard
    private let hotkeyDefaultsKey = "macditto.hotkey"
    private let launchAtLoginDefaultsKey = "macditto.launchAtLoginEnabled"

    private init() {
        if let savedHotkeyData = defaults.data(forKey: hotkeyDefaultsKey),
           let decoded = try? JSONDecoder().decode(HotkeyConfiguration.self, from: savedHotkeyData) {
            hotkey = decoded
        } else {
            hotkey = .default
        }

        if #available(macOS 13.0, *) {
            launchAtLoginEnabled = SMAppService.mainApp.status == .enabled || defaults.bool(forKey: launchAtLoginDefaultsKey)
        } else {
            launchAtLoginEnabled = defaults.bool(forKey: launchAtLoginDefaultsKey)
        }
    }

    var hotkeyOption: HotkeyOption {
        HotkeyOption.option(for: hotkey.keyCode)
    }

    var hotkeyDisplayName: String {
        "\(hotkey.modifierPreset.displayName)+\(hotkeyOption.key)"
    }

    func updateHotkeyModifier(_ modifierPreset: HotkeyModifierPreset) {
        hotkey.modifierPreset = modifierPreset
        persistHotkey()
    }

    func updateHotkeyKey(_ option: HotkeyOption) {
        hotkey.keyCode = option.keyCode
        persistHotkey()
    }

    func setLaunchAtLoginEnabled(_ enabled: Bool) {
        do {
            try LaunchAtLoginController.setEnabled(enabled)
            launchAtLoginEnabled = enabled
            launchAtLoginError = nil
            defaults.set(enabled, forKey: launchAtLoginDefaultsKey)
        } catch {
            launchAtLoginError = error.localizedDescription
        }
    }

    private func persistHotkey() {
        if let encoded = try? JSONEncoder().encode(hotkey) {
            defaults.set(encoded, forKey: hotkeyDefaultsKey)
        }
    }
}

enum LaunchAtLoginController {
    static func setEnabled(_ enabled: Bool) throws {
        if #available(macOS 13.0, *) {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        }
    }
}
