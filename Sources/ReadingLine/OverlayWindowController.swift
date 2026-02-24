import AppKit

// Transparent full-screen window per display; passes all mouse events through.
final class OverlayWindowController {

    private var windows: [NSScreen: NSWindow] = [:]
    private var overlayViews: [NSScreen: OverlayView] = [:]

    init() {
        setupWindows()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup

    private func setupWindows() {
        for screen in NSScreen.screens { createWindow(for: screen) }
    }

    private func createWindow(for screen: NSScreen) {
        let win = NSWindow(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false,
            screen: screen
        )
        win.backgroundColor = .clear
        win.isOpaque = false
        win.hasShadow = false
        win.ignoresMouseEvents = true
        win.level = .screenSaver
        win.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        win.isReleasedWhenClosed = false

        let view = OverlayView(frame: CGRect(origin: .zero, size: screen.frame.size))
        view.autoresizingMask = [.width, .height]
        win.contentView = view
        win.orderFrontRegardless()

        windows[screen] = win
        overlayViews[screen] = view
    }

    // MARK: - Mouse update

    // Receives AppKit global coordinates (bottom-left origin); no conversion needed.
    func updateMousePosition(_ appKitPoint: CGPoint) {
        guard AppSettings.shared.isEnabled else {
            for view in overlayViews.values { view.mouseY = -100; view.mouseX = -100 }
            return
        }
        for (screen, view) in overlayViews {
            if screen.frame.contains(appKitPoint) {
                view.mouseY = appKitPoint.y - screen.frame.origin.y
                view.mouseX = appKitPoint.x - screen.frame.origin.x
            } else {
                view.mouseY = -100
                view.mouseX = -100
            }
        }
    }

    // MARK: - Visibility

    func setVisible(_ visible: Bool) {
        for win in windows.values {
            visible ? win.orderFrontRegardless() : win.orderOut(nil)
        }
        if !visible {
            for view in overlayViews.values { view.mouseY = -100; view.mouseX = -100 }
        }
    }

    // MARK: - Screen change

    @objc private func screensChanged() {
        for win in windows.values { win.close() }
        windows.removeAll()
        overlayViews.removeAll()
        setupWindows()
    }
}
