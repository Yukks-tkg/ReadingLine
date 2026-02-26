import AppKit
import Combine
import ServiceManagement

final class AppSettings: ObservableObject {

    static let shared = AppSettings()

    @Published var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: Keys.isEnabled) }
    }

    @Published var isVertical: Bool {
        didSet { UserDefaults.standard.set(isVertical, forKey: Keys.isVertical) }
    }

    @Published var lineColor: NSColor {
        didSet { saveColor(lineColor, forKey: Keys.lineColor) }
    }

    @Published var lineThickness: Double {
        didSet { UserDefaults.standard.set(lineThickness, forKey: Keys.lineThickness) }
    }

    @Published var lineOpacity: Double {
        didSet { UserDefaults.standard.set(lineOpacity, forKey: Keys.lineOpacity) }
    }

    // nil = full screen width / height
    @Published var lineLength: Double? {
        didSet {
            if let length = lineLength {
                UserDefaults.standard.set(length, forKey: Keys.lineLength)
                UserDefaults.standard.set(true,   forKey: Keys.hasCustomLength)
            } else {
                UserDefaults.standard.set(false, forKey: Keys.hasCustomLength)
            }
        }
    }

    // Carbon key code (0 = no shortcut, default: 37 = L)
    @Published var shortcutKeyCode: Int {
        didSet { UserDefaults.standard.set(shortcutKeyCode, forKey: Keys.shortcutKeyCode) }
    }

    // NSEvent.ModifierFlags rawValue stored as Int
    @Published var shortcutModifiers: Int {
        didSet { UserDefaults.standard.set(shortcutModifiers, forKey: Keys.shortcutModifiers) }
    }

    // Display character shown in settings (e.g. "L")
    @Published var shortcutKeyChar: String {
        didSet { UserDefaults.standard.set(shortcutKeyChar, forKey: Keys.shortcutKeyChar) }
    }

    // MARK: - Init

    private init() {
        let ud = UserDefaults.standard
        isEnabled     = ud.object(forKey: Keys.isEnabled)    as? Bool   ?? true
        isVertical    = ud.object(forKey: Keys.isVertical)   as? Bool   ?? false
        lineThickness = ud.object(forKey: Keys.lineThickness) as? Double ?? 2.0
        lineOpacity   = ud.object(forKey: Keys.lineOpacity)   as? Double ?? 0.5
        lineLength    = ud.bool(forKey: Keys.hasCustomLength) ? ud.double(forKey: Keys.lineLength) : nil
        lineColor     = Self.loadColor(forKey: Keys.lineColor) ?? .systemRed

        // Default shortcut: ⌘⇧L
        let defaultMods = Int(NSEvent.ModifierFlags.command.rawValue | NSEvent.ModifierFlags.shift.rawValue)
        shortcutKeyCode   = ud.object(forKey: Keys.shortcutKeyCode)   as? Int    ?? 37
        shortcutModifiers = ud.object(forKey: Keys.shortcutModifiers) as? Int    ?? defaultMods
        shortcutKeyChar   = ud.object(forKey: Keys.shortcutKeyChar)   as? String ?? "L"
    }

    // MARK: - Keys

    private enum Keys {
        static let isEnabled        = "isEnabled"
        static let isVertical       = "isVertical"
        static let lineColor        = "lineColor"
        static let lineThickness    = "lineThickness"
        static let lineOpacity      = "lineOpacity"
        static let lineLength       = "lineLength"
        static let hasCustomLength  = "hasCustomLength"
        static let shortcutKeyCode   = "shortcutKeyCode"
        static let shortcutModifiers = "shortcutModifiers"
        static let shortcutKeyChar   = "shortcutKeyChar"
        static let suppressWelcome = "suppressWelcome"
    }

    var showWelcomeOnLaunch: Bool {
        get { !UserDefaults.standard.bool(forKey: Keys.suppressWelcome) }
        set { UserDefaults.standard.set(!newValue, forKey: Keys.suppressWelcome) }
    }

    // MARK: - Launch at Login

    @available(macOS 13.0, *)
    var launchAtLogin: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("SMAppService error: \(error)")
            }
        }
    }

    // MARK: - Color helpers

    private func saveColor(_ color: NSColor, forKey key: String) {
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: color,
                                                        requiringSecureCoding: false) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private static func loadColor(forKey key: String) -> NSColor? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: data)
        else { return nil }
        return color
    }
}
