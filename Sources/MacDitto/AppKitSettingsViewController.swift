import AppKit
import Combine

@MainActor
final class AppKitSettingsViewController: NSViewController {
    private let settings = AppSettings.shared
    private var cancellables = Set<AnyCancellable>()

    private let modifierPopup = NSPopUpButton(frame: .zero, pullsDown: false)
    private let keyPopup = NSPopUpButton(frame: .zero, pullsDown: false)
    private let shortcutLabel = NSTextField(labelWithString: "")
    private let launchAtLoginCheckbox = NSButton(checkboxWithTitle: "Launch at Login", target: nil, action: nil)
    private let errorLabel = NSTextField(labelWithString: "")
    private let contentStack = NSStackView()

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 360, height: 220))

        let titleLabel = NSTextField(labelWithString: "Settings")
        titleLabel.font = .systemFont(ofSize: 22, weight: .semibold)

        let hotkeyLabel = sectionLabel("Hotkey")
        let startupLabel = sectionLabel("Startup")

        let modifierRow = settingsRow(label: "Modifier", control: modifierPopup, controlWidth: 170)
        let keyRow = settingsRow(label: "Key", control: keyPopup, controlWidth: 90)

        shortcutLabel.font = .systemFont(ofSize: 12)
        shortcutLabel.textColor = .secondaryLabelColor

        errorLabel.font = .systemFont(ofSize: 12)
        errorLabel.textColor = .systemRed
        errorLabel.lineBreakMode = .byWordWrapping
        errorLabel.maximumNumberOfLines = 3

        modifierPopup.target = self
        modifierPopup.action = #selector(modifierChanged)
        keyPopup.target = self
        keyPopup.action = #selector(keyChanged)
        launchAtLoginCheckbox.target = self
        launchAtLoginCheckbox.action = #selector(launchAtLoginChanged)

        modifierPopup.addItems(withTitles: HotkeyModifierPreset.allCases.map(\.displayName))
        keyPopup.addItems(withTitles: HotkeyOption.all.map(\.key))

        contentStack.orientation = .vertical
        contentStack.alignment = .leading
        contentStack.spacing = 12
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        [
            titleLabel,
            hotkeyLabel,
            modifierRow,
            keyRow,
            shortcutLabel,
            startupLabel,
            launchAtLoginCheckbox,
            errorLabel
        ].forEach { contentStack.addArrangedSubview($0) }

        view.addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -20)
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        bindSettings()
        refreshUI()
    }

    private func bindSettings() {
        settings.$hotkey
            .sink { [weak self] _ in
                self?.refreshUI()
            }
            .store(in: &cancellables)

        settings.$launchAtLoginEnabled
            .sink { [weak self] _ in
                self?.refreshUI()
            }
            .store(in: &cancellables)

        settings.$launchAtLoginError
            .sink { [weak self] _ in
                self?.refreshUI()
            }
            .store(in: &cancellables)
    }

    private func refreshUI() {
        if let modifierIndex = HotkeyModifierPreset.allCases.firstIndex(of: settings.hotkey.modifierPreset) {
            modifierPopup.selectItem(at: modifierIndex)
        }

        if let keyIndex = HotkeyOption.all.firstIndex(of: settings.hotkeyOption) {
            keyPopup.selectItem(at: keyIndex)
        }

        launchAtLoginCheckbox.state = settings.launchAtLoginEnabled ? .on : .off
        shortcutLabel.stringValue = "Current shortcut: \(settings.hotkeyDisplayName)"
        errorLabel.stringValue = settings.launchAtLoginError ?? ""
        errorLabel.isHidden = settings.launchAtLoginError == nil
    }

    private func sectionLabel(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        return label
    }

    private func settingsRow(label: String, control: NSView, controlWidth: CGFloat) -> NSView {
        let title = NSTextField(labelWithString: label)
        title.textColor = .secondaryLabelColor
        title.alignment = .left
        title.setContentHuggingPriority(.required, for: .horizontal)
        title.widthAnchor.constraint(equalToConstant: 70).isActive = true

        control.translatesAutoresizingMaskIntoConstraints = false
        control.widthAnchor.constraint(equalToConstant: controlWidth).isActive = true
        control.heightAnchor.constraint(equalToConstant: 28).isActive = true

        let row = NSStackView(views: [title, control])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 12
        return row
    }

    @objc private func modifierChanged() {
        let index = modifierPopup.indexOfSelectedItem
        guard HotkeyModifierPreset.allCases.indices.contains(index) else { return }
        settings.updateHotkeyModifier(HotkeyModifierPreset.allCases[index])
    }

    @objc private func keyChanged() {
        let index = keyPopup.indexOfSelectedItem
        guard HotkeyOption.all.indices.contains(index) else { return }
        settings.updateHotkeyKey(HotkeyOption.all[index])
    }

    @objc private func launchAtLoginChanged() {
        settings.setLaunchAtLoginEnabled(launchAtLoginCheckbox.state == .on)
    }
}
