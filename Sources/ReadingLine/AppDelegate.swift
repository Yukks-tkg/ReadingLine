import AppKit
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusBarController: StatusBarController?
    private var overlayWindowController: OverlayWindowController?
    private var mouseTracker: MouseTracker?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let overlay = OverlayWindowController()
        overlayWindowController = overlay

        let tracker = MouseTracker()
        mouseTracker = tracker
        tracker.onMouseMove = { [weak overlay] point in
            overlay?.updateMousePosition(point)
        }
        tracker.start()

        statusBarController = StatusBarController()

        AppSettings.shared.$isEnabled
            .receive(on: RunLoop.main)
            .sink { [weak overlay, weak tracker] enabled in
                overlay?.setVisible(enabled)
                if enabled {
                    tracker?.start()
                    overlay?.updateMousePosition(NSEvent.mouseLocation)
                } else {
                    tracker?.stop()
                }
            }
            .store(in: &cancellables)

        setupHotKey()

        Publishers.CombineLatest(
            AppSettings.shared.$shortcutKeyCode,
            AppSettings.shared.$shortcutModifiers
        )
        .dropFirst()
        .receive(on: RunLoop.main)
        .sink { [weak self] _, _ in self?.setupHotKey() }
        .store(in: &cancellables)
    }

    private func setupHotKey() {
        let s = AppSettings.shared
        HotKeyManager.shared.onToggle = { AppSettings.shared.isEnabled.toggle() }
        let mods = NSEvent.ModifierFlags(rawValue: UInt(s.shortcutModifiers))
        HotKeyManager.shared.register(keyCode: s.shortcutKeyCode, modifiers: mods)
    }
}
