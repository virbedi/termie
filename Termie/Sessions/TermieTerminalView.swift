import AppKit
import SwiftTerm

/// Owns a bell callback that can be fired from SwiftTerm's nonisolated bell hook.
final class BellRelay: @unchecked Sendable {
    private let lock = NSLock()
    private var handler: (@MainActor () -> Void)?

    func set(_ handler: (@MainActor () -> Void)?) {
        lock.lock()
        self.handler = handler
        lock.unlock()
    }

    func fire() {
        lock.lock()
        let handler = handler
        lock.unlock()
        DispatchQueue.main.async {
            handler?()
        }
    }
}

/// Coalesces PTY output bursts so the UI hears "still writing" without a hop per chunk.
final class OutputPing: @unchecked Sendable {
    private let lock = NSLock()
    private var pending = false
    private var handler: (@MainActor () -> Void)?

    func set(_ handler: (@MainActor () -> Void)?) {
        lock.lock()
        self.handler = handler
        lock.unlock()
    }

    func ping() {
        lock.lock()
        if pending {
            lock.unlock()
            return
        }
        pending = true
        let handler = handler
        lock.unlock()
        DispatchQueue.main.async { [weak self] in
            self?.lock.lock()
            self?.pending = false
            self?.lock.unlock()
            handler?()
        }
    }
}

final class TermieTerminalView: LocalProcessTerminalView {
    var onFocus: (() -> Void)?
    /// Fired when the view first has a usable size so the shell can start after layout.
    var onUsableSize: (() -> Void)?
    /// While parked off the grid, ignore the zero frame SwiftUI applies as the tile is removed.
    var suppressTinyFrames = false
    private let bellRelay = BellRelay()

    init(font: NSFont) {
        let options = TerminalOptions(scrollback: 10_000)
        super.init(frame: .zero, font: font, options: options)
        bellStyle = .visual
        allowMouseReporting = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        bellStyle = .visual
        allowMouseReporting = true
    }

    func setBellHandler(_ handler: (@MainActor () -> Void)?) {
        bellRelay.set(handler)
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

    nonisolated override func bell(source: Terminal) {
        super.bell(source: source)
        bellRelay.fire()
    }

    override func mouseDown(with event: NSEvent) {
        onFocus?()
        super.mouseDown(with: event)
    }
}
