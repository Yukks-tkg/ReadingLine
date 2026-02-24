import AppKit
import Combine

// Transparent view that draws a single horizontal or vertical line.
final class OverlayView: NSView {

    var mouseY: CGFloat = -100 {
        didSet { if oldValue != mouseY { needsDisplay = true } }
    }

    var mouseX: CGFloat = -100 {
        didSet { if oldValue != mouseX { needsDisplay = true } }
    }

    private let settings = AppSettings.shared
    private var cancellable: AnyCancellable?

    override init(frame: NSRect) {
        super.init(frame: frame)
        cancellable = settings.$isVertical
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.needsDisplay = true }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var isOpaque: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.clear.set()
        bounds.fill()

        guard settings.isEnabled else { return }

        let lineWidth = CGFloat(settings.lineThickness)
        let color = settings.lineColor.withAlphaComponent(CGFloat(settings.lineOpacity))

        if settings.isVertical {
            guard mouseX >= 0 else { return }
            let h = bounds.height
            let length = settings.lineLength.map { min(CGFloat($0), h) } ?? h
            let startY = (h - length) / 2
            let path = NSBezierPath()
            path.lineWidth = lineWidth
            path.move(to: NSPoint(x: mouseX, y: startY))
            path.line(to: NSPoint(x: mouseX, y: startY + length))
            color.setStroke()
            path.stroke()
        } else {
            guard mouseY >= 0 else { return }
            let w = bounds.width
            let length = settings.lineLength.map { min(CGFloat($0), w) } ?? w
            let startX = (w - length) / 2
            let path = NSBezierPath()
            path.lineWidth = lineWidth
            path.move(to: NSPoint(x: startX, y: mouseY))
            path.line(to: NSPoint(x: startX + length, y: mouseY))
            color.setStroke()
            path.stroke()
        }
    }
}
