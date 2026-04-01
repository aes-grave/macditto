import AppKit
import SwiftUI

struct ClipboardTableView: NSViewRepresentable {
    let items: [ClipboardItem]
    @Binding var selectedItemID: ClipboardItem.ID?
    let onActivateItem: (ClipboardItem) -> Void
    let onDismiss: () -> Void
    let focusToken: Int

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let tableView = HistoryTableView()
        tableView.headerView = nil
        tableView.usesAlternatingRowBackgroundColors = false
        tableView.selectionHighlightStyle = .regular
        tableView.rowHeight = 92
        tableView.focusRingType = .none
        tableView.delegate = context.coordinator
        tableView.dataSource = context.coordinator
        tableView.target = context.coordinator
        tableView.doubleAction = #selector(Coordinator.doubleClicked)
        tableView.onActivateSelection = { [weak coordinator = context.coordinator] in
            coordinator?.activateSelection()
        }
        tableView.onDismiss = onDismiss

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("history"))
        column.resizingMask = .autoresizingMask
        tableView.addTableColumn(column)

        let scrollView = NSScrollView()
        scrollView.borderType = .bezelBorder
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.documentView = tableView

        context.coordinator.tableView = tableView
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.items = items
        context.coordinator.tableView?.reloadData()
        context.coordinator.restoreSelection()

        if context.coordinator.lastFocusToken != focusToken {
            context.coordinator.lastFocusToken = focusToken
            DispatchQueue.main.async {
                if let tableView = context.coordinator.tableView {
                    tableView.window?.makeFirstResponder(tableView)
                }
            }
        }
    }

    @MainActor
    final class Coordinator: NSObject, NSTableViewDataSource, NSTableViewDelegate {
        var parent: ClipboardTableView
        var items: [ClipboardItem]
        weak var tableView: NSTableView?
        var lastFocusToken: Int = 0

        init(_ parent: ClipboardTableView) {
            self.parent = parent
            self.items = parent.items
        }

        func numberOfRows(in tableView: NSTableView) -> Int {
            items.count
        }

        func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
            guard items.indices.contains(row) else { return false }
            parent.selectedItemID = items[row].id
            return true
        }

        func tableViewSelectionDidChange(_ notification: Notification) {
            guard let tableView else { return }
            let row = tableView.selectedRow
            guard items.indices.contains(row) else {
                parent.selectedItemID = nil
                return
            }
            parent.selectedItemID = items[row].id
        }

        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
            guard items.indices.contains(row) else { return nil }
            return ClipboardTableCellView(item: items[row], isSelected: items[row].id == parent.selectedItemID)
        }

        func restoreSelection() {
            guard let tableView else { return }
            guard !items.isEmpty else {
                tableView.deselectAll(nil)
                return
            }

            let index = items.firstIndex(where: { $0.id == parent.selectedItemID }) ?? 0
            parent.selectedItemID = items[index].id
            tableView.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
            tableView.scrollRowToVisible(index)
        }

        @objc func doubleClicked() {
            activateSelection()
        }

        func activateSelection() {
            guard let selected = items.first(where: { $0.id == parent.selectedItemID }) else { return }
            parent.onActivateItem(selected)
        }
    }
}

private final class HistoryTableView: NSTableView {
    var onActivateSelection: (() -> Void)?
    var onDismiss: (() -> Void)?

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 36, 76:
            onActivateSelection?()
        case 53:
            onDismiss?()
        default:
            super.keyDown(with: event)
        }
    }
}

private final class ClipboardTableCellView: NSTableCellView {
    init(item: ClipboardItem, isSelected: Bool) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        let preview = PreviewBadgeView(item: item)
        preview.translatesAutoresizingMaskIntoConstraints = false

        let kindLabel = NSTextField(labelWithString: kindText(for: item.kind))
        kindLabel.font = .monospacedSystemFont(ofSize: 10, weight: .medium)
        kindLabel.textColor = .secondaryLabelColor

        let timestampLabel = NSTextField(labelWithString: item.createdAt.formatted(date: .abbreviated, time: .shortened))
        timestampLabel.font = .systemFont(ofSize: 11)
        timestampLabel.textColor = .secondaryLabelColor

        let headerRow = NSStackView(views: [kindLabel, timestampLabel])
        headerRow.orientation = .horizontal
        headerRow.alignment = .centerY
        headerRow.spacing = 8

        if item.pinned {
            let pinned = BadgeLabel(text: "PINNED")
            headerRow.insertArrangedSubview(pinned, at: 0)
        }

        let valueLabel = NSTextField(wrappingLabelWithString: item.value)
        valueLabel.font = .systemFont(ofSize: 13)
        valueLabel.lineBreakMode = .byTruncatingTail
        valueLabel.maximumNumberOfLines = item.kind == .image ? 1 : 3

        let textStack = NSStackView(views: [headerRow, valueLabel])
        textStack.orientation = .vertical
        textStack.alignment = .leading
        textStack.spacing = 4
        textStack.translatesAutoresizingMaskIntoConstraints = false

        let row = NSStackView(views: [preview, textStack])
        row.orientation = .horizontal
        row.alignment = .top
        row.spacing = 10
        row.translatesAutoresizingMaskIntoConstraints = false

        let background = NSView()
        background.translatesAutoresizingMaskIntoConstraints = false
        background.wantsLayer = true
        background.layer?.cornerRadius = 8
        background.layer?.backgroundColor = (isSelected ? NSColor.controlAccentColor.withAlphaComponent(0.12) : .clear).cgColor

        addSubview(background)
        addSubview(row)

        NSLayoutConstraint.activate([
            background.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            background.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            background.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2),
            background.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),

            row.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            row.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -10),
            row.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -10),

            preview.widthAnchor.constraint(equalToConstant: 72),
            preview.heightAnchor.constraint(equalToConstant: 72)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func kindText(for kind: ClipboardItemKind) -> String {
        switch kind {
        case .text: return "TEXT"
        case .url: return "URL"
        case .fileReference: return "FILE"
        case .html: return "HTML"
        case .image: return "IMAGE"
        }
    }
}

private final class PreviewBadgeView: NSView {
    init(item: ClipboardItem) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        wantsLayer = true
        layer?.cornerRadius = 10
        layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.12).cgColor

        if item.kind == .image, let payload = item.payload, let image = NSImage(data: payload) {
            let imageView = NSImageView(image: image)
            imageView.imageScaling = .scaleAxesIndependently
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.wantsLayer = true
            imageView.layer?.cornerRadius = 10
            imageView.layer?.masksToBounds = true
            addSubview(imageView)

            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: topAnchor),
                imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
                imageView.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
        } else {
            let imageView = NSImageView()
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
            imageView.contentTintColor = .controlAccentColor
            imageView.image = NSImage(systemSymbolName: symbolName(for: item.kind), accessibilityDescription: nil)
            addSubview(imageView)

            NSLayoutConstraint.activate([
                imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
                imageView.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func symbolName(for kind: ClipboardItemKind) -> String {
        switch kind {
        case .text: return "text.alignleft"
        case .url: return "link"
        case .fileReference: return "doc"
        case .html: return "chevron.left.forwardslash.chevron.right"
        case .image: return "photo"
        }
    }
}

private final class BadgeLabel: NSTextField {
    init(text: String) {
        super.init(frame: .zero)
        stringValue = text
        isEditable = false
        isBezeled = false
        drawsBackground = true
        backgroundColor = NSColor.systemYellow.withAlphaComponent(0.25)
        font = .monospacedSystemFont(ofSize: 10, weight: .medium)
        textColor = .labelColor
        lineBreakMode = .byClipping
        cell?.wraps = false
        cell?.isScrollable = true
        wantsLayer = true
        layer?.cornerRadius = 4
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
