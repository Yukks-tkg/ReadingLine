import SwiftUI
import AppKit

struct SettingsView: View {

    @ObservedObject private var settings = AppSettings.shared

    // Local state to avoid "Publishing changes from within view updates" warning
    @State private var selectedColor: Color
    @State private var isVerticalLocal: Bool

    init() {
        _selectedColor   = State(initialValue: Color(AppSettings.shared.lineColor))
        _isVerticalLocal = State(initialValue: AppSettings.shared.isVertical)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            previewSection

            Divider()

            HStack {
                Label("向き", systemImage: "arrow.up.arrow.down")
                    .frame(width: 120, alignment: .leading)
                Picker("", selection: $isVerticalLocal) {
                    Text("横線（横書き）").tag(false)
                    Text("縦線（縦書き）").tag(true)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .onChange(of: isVerticalLocal) { newValue in
                    settings.isVertical = newValue
                }
                .onReceive(settings.$isVertical) { newValue in
                    isVerticalLocal = newValue
                }
            }

            HStack {
                Label("線の色", systemImage: "paintpalette")
                    .frame(width: 120, alignment: .leading)
                ColorPicker("", selection: $selectedColor)
                    .labelsHidden()
                    .onChange(of: selectedColor) { newColor in
                        settings.lineColor = NSColor(newColor)
                    }
            }

            SliderRow(
                label: "線の太さ",
                icon: "line.horizontal.3",
                value: $settings.lineThickness,
                range: 1...5,
                unit: "px"
            )

            SliderRow(
                label: "線の透明度",
                icon: "circle.lefthalf.filled",
                value: $settings.lineOpacity,
                range: 0.1...0.9,
                unit: "%",
                displayScale: 100,
                fractionDigits: 0
            )

            lineLengthSection

            shortcutSection
        }
        .padding(24)
        .frame(width: 420)
    }

    // MARK: - Preview

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("プレビュー")
                .font(.caption)
                .foregroundStyle(.secondary)

            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(nsColor: .windowBackgroundColor))
                    .frame(height: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                    )

                if settings.isVertical {
                    Rectangle()
                        .fill(Color(settings.lineColor).opacity(settings.lineOpacity))
                        .frame(width: settings.lineThickness, height: previewLineHeight)
                } else {
                    Rectangle()
                        .fill(Color(settings.lineColor).opacity(settings.lineOpacity))
                        .frame(width: previewLineWidth, height: settings.lineThickness)
                }
            }
        }
    }

    private var previewLineWidth: CGFloat {
        settings.lineLength.map { min(CGFloat($0) / 10, 332) } ?? 332
    }

    private var previewLineHeight: CGFloat {
        settings.lineLength.map { min(CGFloat($0) / 10, 56) } ?? 56
    }

    // MARK: - Line Length

    private var lineLengthSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label("線の長さ", systemImage: settings.isVertical ? "arrow.up.and.down" : "arrow.left.and.right")
                    .frame(width: 120, alignment: .leading)
                Toggle(settings.isVertical ? "画面高さいっぱい" : "画面幅いっぱい", isOn: Binding(
                    get: { settings.lineLength == nil },
                    set: { settings.lineLength = $0 ? nil : 800 }
                ))
                .toggleStyle(.checkbox)
            }

            if settings.lineLength != nil {
                HStack {
                    Spacer().frame(width: 128)
                    Slider(value: Binding(
                        get: { settings.lineLength ?? 800 },
                        set: { settings.lineLength = $0 }
                    ), in: 100...2560, step: 10)
                    .padding(.bottom, 3)
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(Color(nsColor: .windowBackgroundColor))
                            .frame(height: 3)
                    }
                    Text("\(Int(settings.lineLength ?? 800)) px")
                        .monospacedDigit()
                        .frame(width: 64, alignment: .trailing)
                }
            }
        }
    }

    // MARK: - Shortcut

    private var shortcutSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label("ON/OFFキー", systemImage: "keyboard")
                    .frame(width: 120, alignment: .leading)

                ShortcutRecorderView(
                    keyCode:   $settings.shortcutKeyCode,
                    modifiers: $settings.shortcutModifiers,
                    keyChar:   $settings.shortcutKeyChar
                )
                .frame(width: 160, height: 24)

                Button("デフォルト") {
                    let defaultMods = Int(
                        NSEvent.ModifierFlags.command.rawValue |
                        NSEvent.ModifierFlags.shift.rawValue
                    )
                    settings.shortcutKeyCode   = 37
                    settings.shortcutModifiers = defaultMods
                    settings.shortcutKeyChar   = "L"
                }
                .buttonStyle(.borderless)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            HStack {
                Spacer().frame(width: 128)
                Text("クリックして変更 / Delete でクリア")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - SliderRow

private struct SliderRow: View {
    let label: String
    let icon: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let unit: String
    var displayScale: Double = 1
    var fractionDigits: Int = 1

    var body: some View {
        HStack {
            Label(label, systemImage: icon)
                .frame(width: 120, alignment: .leading)
            Slider(value: $value, in: range)
            Text(formattedValue)
                .monospacedDigit()
                .frame(width: 56, alignment: .trailing)
        }
    }

    private var formattedValue: String {
        let number = String(format: "%.\(fractionDigits)f", value * displayScale)
        return "\(number)\(unit)"
    }
}

// MARK: - Window Controller

final class SettingsWindowController: NSWindowController {

    convenience init() {
        let hostingController = NSHostingController(rootView: SettingsView())
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Reading Line — 設定"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        self.init(window: window)
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        window?.center()
        window?.makeKeyAndOrderFront(sender)
    }
}
