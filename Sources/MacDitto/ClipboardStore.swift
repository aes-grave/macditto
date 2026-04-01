import AppKit
import Combine
import Foundation

enum ClipboardItemKind: String, Codable {
    case text
    case url
    case fileReference
}

struct ClipboardItem: Identifiable, Codable, Equatable {
    let id: UUID
    var value: String
    let createdAt: Date
    var pinned: Bool
    var kind: ClipboardItemKind

    init(
        id: UUID = UUID(),
        value: String,
        createdAt: Date = Date(),
        pinned: Bool = false,
        kind: ClipboardItemKind = .text
    ) {
        self.id = id
        self.value = value
        self.createdAt = createdAt
        self.pinned = pinned
        self.kind = kind
    }
}

@MainActor
final class ClipboardStore: ObservableObject {
    static let shared = ClipboardStore()

    @Published private(set) var items: [ClipboardItem] = []
    @Published var searchText: String = ""

    private let pasteboard = NSPasteboard.general
    private var pasteboardChangeCount: Int = NSPasteboard.general.changeCount
    private var timer: Timer?
    private var suppressNextCapture = false
    private let maxItems = 300
    private let persistenceURL: URL

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let directory = appSupport.appendingPathComponent("MacDitto", isDirectory: true)
        self.persistenceURL = directory.appendingPathComponent("history.json")
        createPersistenceDirectoryIfNeeded(directory)
        loadHistory()
        startMonitoring()
    }

    deinit {
        timer?.invalidate()
    }

    var filteredItems: [ClipboardItem] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return sorted(items)
        }
        let needle = searchText.lowercased()
        return sorted(items).filter { $0.value.lowercased().contains(needle) }
    }

    func copyToClipboard(_ item: ClipboardItem) {
        suppressNextCapture = true
        pasteboard.clearContents()
        pasteboard.setString(item.value, forType: .string)
    }

    func delete(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
        persistHistory()
    }

    func togglePin(_ item: ClipboardItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].pinned.toggle()
        persistHistory()
    }

    func clearUnpinned() {
        items.removeAll { !$0.pinned }
        persistHistory()
    }

    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.45, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.captureIfPasteboardChanged()
            }
        }
    }

    private func captureIfPasteboardChanged() {
        guard pasteboard.changeCount != pasteboardChangeCount else { return }
        pasteboardChangeCount = pasteboard.changeCount

        if suppressNextCapture {
            suppressNextCapture = false
            return
        }

        guard let next = currentPasteboardItem() else { return }

        if let first = items.first, first.value == next.value, first.kind == next.kind {
            return
        }

        items.insert(next, at: 0)
        enforceItemLimit()
        persistHistory()
    }

    private func currentPasteboardItem() -> ClipboardItem? {
        if let text = pasteboard.string(forType: .string)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !text.isEmpty {
            return ClipboardItem(value: text, kind: .text)
        }

        if let url = pasteboard.string(forType: .URL)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !url.isEmpty {
            return ClipboardItem(value: url, kind: .url)
        }

        if let files = pasteboard.readObjects(forClasses: [NSURL.self]),
           let first = files.first as? URL {
            return ClipboardItem(value: first.path, kind: .fileReference)
        }

        return nil
    }

    private func enforceItemLimit() {
        if items.count <= maxItems { return }
        let pinnedItems = items.filter { $0.pinned }
        let regular = items.filter { !$0.pinned }
        let keptRegular = Array(regular.prefix(max(0, maxItems - pinnedItems.count)))
        items = sorted(pinnedItems + keptRegular)
    }

    private func sorted(_ source: [ClipboardItem]) -> [ClipboardItem] {
        source.sorted { lhs, rhs in
            if lhs.pinned != rhs.pinned {
                return lhs.pinned && !rhs.pinned
            }
            return lhs.createdAt > rhs.createdAt
        }
    }

    private func createPersistenceDirectoryIfNeeded(_ directory: URL) {
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch {
            NSLog("MacDitto: failed to create persistence directory: \(error.localizedDescription)")
        }
    }

    private func loadHistory() {
        guard FileManager.default.fileExists(atPath: persistenceURL.path) else { return }

        do {
            let data = try Data(contentsOf: persistenceURL)
            let decoded = try JSONDecoder().decode([ClipboardItem].self, from: data)
            items = decoded
        } catch {
            NSLog("MacDitto: failed to load history: \(error.localizedDescription)")
        }
    }

    private func persistHistory() {
        do {
            let data = try JSONEncoder().encode(items)
            try data.write(to: persistenceURL, options: .atomic)
        } catch {
            NSLog("MacDitto: failed to persist history: \(error.localizedDescription)")
        }
    }
}
