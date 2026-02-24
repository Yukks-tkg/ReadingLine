import AppKit
import SwiftUI

// Records a key combo. Click to start recording; press a key to confirm.
// Escape cancels, Delete clears.
struct ShortcutRecorderView: NSViewRepresentable {

    @Binding var keyCode: Int
    @Binding var modifiers: Int
    @Binding var keyChar: String

    func makeNSView(context: Context) -> RecorderField {
        let field = RecorderField()
        field.coordinator = context.coordinator
        field.updateDisplay(keyCode: keyCode, modifiers: modifiers, keyChar: keyChar)
        return field
    }

    func updateNSView(_ nsView: RecorderField, context: Context) {
        nsView.updateDisplay(keyCode: keyCode, modifiers: modifiers, keyChar: keyChar)
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator {
        var parent: ShortcutRecorderView
        init(_ parent: ShortcutRecorderView) { self.parent = parent }

        func didRecord(keyCode: Int, modifiers: Int, keyChar: String) {
            parent.keyCode    = keyCode
            parent.modifiers  = modifiers
            parent.keyChar    = keyChar
        }
        func didClear() {
            parent.keyCode    = 0
            parent.modifiers  = 0
            parent.keyChar    = ""
        }
    }
}

// MARK: - RecorderField

final class RecorderField: NSTextField {

    weak var coordinator: ShortcutRecorderView.Coordinator?
    private var isRecording = false
    private var previousDisplay = ""

    override init(frame: NSRect) {
        super.init(frame: frame)
        isEditable   = false
        isSelectable = false
        isBezeled    = true
        bezelStyle   = .roundedBezel
        alignment    = .center
        font         = .monospacedSystemFont(ofSize: 13, weight: .regular)
    }
    required init?(coder: NSCoder) { fatalError() }

    func updateDisplay(keyCode: Int, modifiers: Int, keyChar: String) {
        guard !isRecording else { return }
        if keyCode == 0 {
            stringValue = "なし"
            textColor   = .secondaryLabelColor
        } else {
            let flags   = NSEvent.ModifierFlags(rawValue: UInt(modifiers))
            stringValue = modSymbols(flags) + keyChar
            textColor   = .labelColor
        }
        previousDisplay = stringValue
    }

    override func mouseDown(with event: NSEvent) {
        isRecording = true
        stringValue = "⌨ キーを押してください..."
        textColor   = .secondaryLabelColor
        window?.makeFirstResponder(self)
    }

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        guard isRecording else { super.keyDown(with: event); return }

        if event.keyCode == 53 {  // Escape — cancel
            isRecording = false
            stringValue = previousDisplay
            textColor   = .labelColor
            return
        }

        if event.keyCode == 51 || event.keyCode == 117 {  // Delete / Forward Delete — clear
            isRecording = false
            stringValue = "なし"
            textColor   = .secondaryLabelColor
            coordinator?.didClear()
            return
        }

        let mods = event.modifierFlags.intersection([.command, .option, .control, .shift])
        guard !mods.isEmpty else { return }  // require at least one modifier

        let kc  = Int(event.keyCode)
        let ch  = (event.charactersIgnoringModifiers ?? "").uppercased()
        let raw = Int(mods.rawValue)

        isRecording = false
        stringValue = modSymbols(mods) + ch
        textColor   = .labelColor
        coordinator?.didRecord(keyCode: kc, modifiers: raw, keyChar: ch)
    }

    private func modSymbols(_ flags: NSEvent.ModifierFlags) -> String {
        var s = ""
        if flags.contains(.control) { s += "⌃" }
        if flags.contains(.option)  { s += "⌥" }
        if flags.contains(.shift)   { s += "⇧" }
        if flags.contains(.command) { s += "⌘" }
        return s
    }
}
