import AppKit

// Polls NSEvent.mouseLocation at ~60 fps. No Accessibility permission required.
final class MouseTracker {

    var onMouseMove: ((CGPoint) -> Void)?
    private var timer: Timer?

    func start() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.onMouseMove?(NSEvent.mouseLocation)
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }
}
