import AppKit
import Combine

final class StatusBarController {

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private var settingsWindowController: SettingsWindowController?
    private var cancellables = Set<AnyCancellable>()
    private let settings = AppSettings.shared
    private weak var toggleView: MenuToggleView?

    init() {
        configureStatusItem()
        buildMenu()

        // Sync toggle view when shortcut changes the state
        settings.$isEnabled
            .receive(on: RunLoop.main)
            .sink { [weak self] enabled in
                self?.toggleView?.isOn = enabled
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

        let toggle = MenuToggleView(isOn: settings.isEnabled)
        let tw = toggle.intrinsicContentSize
        toggle.frame = NSRect(
            x: width - tw.width - 12,
            y: (height - tw.height) / 2,
            width: tw.width,
            height: tw.height
        )
        toggle.onToggle = { [weak self] isOn in
            self?.settings.isEnabled = isOn
            self?.statusItem.menu?.cancelTracking()
        }

        container.addSubview(label)
        container.addSubview(toggle)
        toggleView = toggle

        return container
    }

    @objc private func openSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController()
        }
        settingsWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - Custom toggle using CALayer for smooth animation

final class MenuToggleView: NSView {

    var isOn: Bool { didSet { guard oldValue != isOn else { return }; updateAppearance(animated: true) } }
    var onToggle: ((Bool) -> Void)?

    private let w: CGFloat = 36
    private let h: CGFloat = 20
    private let pad: CGFloat = 2
    private let trackLayer = CALayer()
    private let thumbLayer = CALayer()

    init(isOn: Bool) {
        self.isOn = isOn
        super.init(frame: NSRect(x: 0, y: 0, width: 36, height: 20))
        wantsLayer = true
        setupLayers()
        updateAppearance(animated: false)
    }
    required init?(coder: NSCoder) { fatalError() }

    override var intrinsicContentSize: NSSize { NSSize(width: w, height: h) }

    private func setupLayers() {
        trackLayer.frame = CGRect(x: 0, y: 0, width: w, height: h)
        trackLayer.cornerRadius = h / 2
        layer?.addSublayer(trackLayer)

        let thumbD = h - pad * 2
        thumbLayer.frame = CGRect(x: pad, y: pad, width: thumbD, height: thumbD)
        thumbLayer.cornerRadius = thumbD / 2
        thumbLayer.backgroundColor = NSColor.white.cgColor
        thumbLayer.shadowColor = NSColor.black.cgColor
        thumbLayer.shadowOpacity = 0.15
        thumbLayer.shadowOffset = CGSize(width: 0, height: -1)
        thumbLayer.shadowRadius = 1
        layer?.addSublayer(thumbLayer)
    }

    private func updateAppearance(animated: Bool) {
        let thumbD = h - pad * 2
        let thumbX = isOn ? w - thumbD - pad : pad
        let trackColor = (isOn ? NSColor.controlAccentColor : NSColor(white: 0.55, alpha: 1)).cgColor

        CATransaction.begin()
        if animated {
            CATransaction.setAnimationDuration(0.22)
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeInEaseOut))
        } else {
            CATransaction.setDisableActions(true)
        }
        thumbLayer.frame = CGRect(x: thumbX, y: pad, width: thumbD, height: thumbD)
        trackLayer.backgroundColor = trackColor
        CATransaction.commit()
    }

    override func mouseDown(with event: NSEvent) {
        isOn.toggle()
        onToggle?(isOn)
    }
}
