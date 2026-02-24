import AppKit
import Combine

final class StatusBarController {

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private var settingsWindowController: SettingsWindowController?
    private var cancellables = Set<AnyCancellable>()
    private let settings = AppSettings.shared
    private weak var enableSwitch: NSSwitch?

    init() {
        configureStatusItem()
        buildMenu()

        // Update switch state when toggled via keyboard shortcut
        settings.$isEnabled
            .receive(on: RunLoop.main)
            .sink { [weak self] enabled in
                self?.enableSwitch?.state = enabled ? .on : .off
            }
            .store(in: &cancellables)
    }

    private func configureStatusItem() {
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "text.cursor",
                                   accessibilityDescription: "Reading Line")
            button.image?.isTemplate = true
        }
    }

    private func buildMenu() {
        let menu = NSMenu()

        let toggleItem = NSMenuItem()
        toggleItem.view = makeSwitchView()
        menu.addItem(toggleItem)

        menu.addItem(.separator())

        let settingsItem = NSMenuItem(
            title: "設定を開く…",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.keyEquivalentModifierMask = .command
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "終了",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        quitItem.keyEquivalentModifierMask = .command
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    private func makeSwitchView() -> NSView {
        let height: CGFloat = 32
        let width: CGFloat = 200
        let container = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))

        let label = NSTextField(labelWithString: "読書ライン")
        label.font = NSFont.menuFont(ofSize: 13)
        label.sizeToFit()
        label.frame.origin = NSPoint(x: 14, y: (height - label.frame.height) / 2)

        let toggle = NSSwitch()
        toggle.state = settings.isEnabled ? .on : .off
        toggle.target = self
        toggle.action = #selector(switchToggled(_:))
        let size = toggle.intrinsicContentSize
        toggle.frame = NSRect(
            x: width - size.width - 10,
            y: (height - size.height) / 2,
            width: size.width,
            height: size.height
        )

        container.addSubview(label)
        container.addSubview(toggle)
        enableSwitch = toggle

        return container
    }

    @objc private func switchToggled(_ sender: NSSwitch) {
        settings.isEnabled = sender.state == .on
    }

    @objc private func openSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController()
        }
        settingsWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
