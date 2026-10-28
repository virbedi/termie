import AppKit
import SwiftTerm
import TermieCore

final class TermieTerminalView: LocalProcessTerminalView {
    var onFocus: (() -> Void)?
    /// Fired when the view first has a usable size so the shell can start after layout.
    var onUsableSize: (() -> Void)?
    /// While parked off the grid, ignore the zero frame SwiftUI applies as the tile is removed.
    var suppressTinyFrames = false
    /// Last theme pushed from SwiftUI so updates can skip a full palette reinstall.
    var appliedTheme: ShellTheme?

    init(font: NSFont) {
        let options = TerminalOptions(scrollback: 10_000)
        super.init(frame: .zero, font: font, options: options)
        bellStyle = .visual
        allowMouseReporting = true
        registerForDraggedTypes(Self.dropTypes)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        bellStyle = .visual
        allowMouseReporting = true
        registerForDraggedTypes(Self.dropTypes)
    }

    override func setFrameSize(_ newSize: NSSize) {
        if suppressTinyFrames, newSize.width < 24 || newSize.height < 24 {
            return
        }
        super.setFrameSize(newSize)
        if newSize.width > 2, newSize.height > 2 {
            onUsableSize?()
        }
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard window != nil, bounds.width > 2, bounds.height > 2 else { return }
        onUsableSize?()
    }

    override func mouseDown(with event: NSEvent) {
        onFocus?()
        super.mouseDown(with: event)
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        acceptsDrop(sender.draggingPasteboard) ? .copy : []
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        acceptsDrop(sender.draggingPasteboard) ? .copy : []
    }

    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        acceptsDrop(sender.draggingPasteboard)
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let pasteboard = sender.draggingPasteboard
        if let paths = filePaths(from: pasteboard) {
            insertDroppedPaths(paths)
            return true
        }
        if let receivers = pasteboard.readObjects(forClasses: [NSFilePromiseReceiver.self], options: nil) as? [NSFilePromiseReceiver],
           !receivers.isEmpty {
            let destination = Self.dropDirectory()
            let inserted = DropInsertion()
            for receiver in receivers {
                receiver.receivePromisedFiles(atDestination: destination, options: [:], operationQueue: .main) { [weak self] url, error in
                    guard let self, error == nil else { return }
                    let quoted = shellDropText(paths: [url.path])
                    guard !quoted.isEmpty else { return }
                    let text = inserted.needsSeparator ? " \(quoted)" : quoted
                    inserted.needsSeparator = true
                    self.insertDroppedText(text)
                }
            }
            return true
        }
        if let path = writeDroppedImage(from: pasteboard) {
            insertDroppedPaths([path])
            return true
        }
        return false
    }

    private func insertDroppedPaths(_ paths: [String]) {
        insertDroppedText(shellDropText(paths: paths))
    }

    private func insertDroppedText(_ text: String) {
        guard !text.isEmpty else { return }
        onFocus?()
        window?.makeFirstResponder(self)
        insertText(text, replacementRange: NSRange(location: 0, length: 0))
    }

    private func acceptsDrop(_ pasteboard: NSPasteboard) -> Bool {
        if filePaths(from: pasteboard) != nil { return true }
        if pasteboard.canReadObject(forClasses: [NSFilePromiseReceiver.self], options: nil) { return true }
        return droppedImage(from: pasteboard) != nil
    }

    private func filePaths(from pasteboard: NSPasteboard) -> [String]? {
        guard let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: [
            .urlReadingFileURLsOnly: true
        ]) as? [URL] else { return nil }
        let paths = urls.map(\.path).filter { !$0.isEmpty }
        return paths.isEmpty ? nil : paths
    }

    private func writeDroppedImage(from pasteboard: NSPasteboard) -> String? {
        guard let image = droppedImage(from: pasteboard) else { return nil }
        let url = Self.dropDirectory().appendingPathComponent("Screenshot \(Self.dropStamp()).\(image.fileExtension)")
        do {
            try image.data.write(to: url)
            return url.path
        } catch {
            return nil
        }
    }

    private func droppedImage(from pasteboard: NSPasteboard) -> (data: Data, fileExtension: String)? {
        if let png = pasteboard.data(forType: .png) { return (png, "png") }
        if let jpeg = pasteboard.data(forType: NSPasteboard.PasteboardType("public.jpeg")) { return (jpeg, "jpg") }
        guard let tiff = pasteboard.data(forType: .tiff),
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else { return nil }
        return (png, "png")
    }

    private static var dropTypes: [NSPasteboard.PasteboardType] {
        var types: [NSPasteboard.PasteboardType] = [
            .fileURL,
            .png,
            .tiff,
            NSPasteboard.PasteboardType("public.jpeg")
        ]
        types += NSFilePromiseReceiver.readableDraggedTypes.map { NSPasteboard.PasteboardType($0) }
        return types
    }

    private static func dropDirectory() -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("Termie", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private static func dropStamp() -> String {
        ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: ".")
    }
}

private final class DropInsertion {
    var needsSeparator = false
}
