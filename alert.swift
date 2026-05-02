import Cocoa
import QuartzCore

class AlertDelegate: NSObject, NSApplicationDelegate {
    let batteryPercent: Int
    var window: NSWindow!
    var powerCheckTimer: Timer?

    init(batteryPercent: Int) {
        self.batteryPercent = batteryPercent
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildWindow()
        closeIfCharging()
        powerCheckTimer = Timer.scheduledTimer(
            timeInterval: 1.0,
            target: self,
            selector: #selector(closeIfCharging),
            userInfo: nil,
            repeats: true
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + 25) {
            NSApplication.shared.terminate(nil)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        powerCheckTimer?.invalidate()
    }

    func buildWindow() {
        guard let screen = NSScreen.main else { return }
        let frame = screen.frame

        window = NSWindow(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.level = .screenSaver
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let root = NSView(frame: NSRect(x: 0, y: 0, width: frame.width, height: frame.height))
        root.wantsLayer = true
        window.contentView = root

        // Dark base overlay
        let overlay = NSView(frame: root.bounds)
        overlay.wantsLayer = true
        overlay.layer?.backgroundColor = NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.5).cgColor
        root.addSubview(overlay)

        // Red vignette — intense at edges, transparent in center
        let vignette = NSView(frame: root.bounds)
        vignette.wantsLayer = true
        let gradient = CAGradientLayer()
        gradient.type = .radial
        gradient.colors = [
            NSColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.0).cgColor,
            NSColor(red: 0.6, green: 0.0, blue: 0.0, alpha: 0.3).cgColor,
            NSColor(red: 0.4, green: 0.0, blue: 0.0, alpha: 0.65).cgColor,
        ]
        gradient.locations = [0.0, 0.55, 1.0]
        gradient.startPoint = CGPoint(x: 0.5, y: 0.5)
        gradient.endPoint = CGPoint(x: 0.0, y: 0.0)
        gradient.frame = vignette.bounds
        vignette.layer?.addSublayer(gradient)
        root.addSubview(vignette)

        // Pulsing vignette animation
        let vignettePulse = CABasicAnimation(keyPath: "opacity")
        vignettePulse.fromValue = 0.7
        vignettePulse.toValue = 1.0
        vignettePulse.duration = 1.8
        vignettePulse.autoreverses = true
        vignettePulse.repeatCount = .infinity
        vignettePulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        vignette.layer?.add(vignettePulse, forKey: "pulse")

        // Glass card
        let cardW: CGFloat = 440
        let cardH: CGFloat = 210
        let cardX = (frame.width - cardW) / 2
        let cardY = (frame.height - cardH) / 2

        let glass = NSVisualEffectView(frame: NSRect(x: cardX, y: cardY, width: cardW, height: cardH))
        glass.material = .hudWindow
        glass.blendingMode = .behindWindow
        glass.state = .active
        glass.wantsLayer = true
        glass.layer?.cornerRadius = 22
        glass.layer?.masksToBounds = true
        glass.layer?.borderColor = NSColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 0.3).cgColor
        glass.layer?.borderWidth = 1
        root.addSubview(glass)

        // Pulsing glow ring around the card
        let glowSize: CGFloat = 8
        let glow = NSView(frame: NSRect(
            x: cardX - glowSize, y: cardY - glowSize,
            width: cardW + glowSize * 2, height: cardH + glowSize * 2
        ))
        glow.wantsLayer = true
        glow.layer?.cornerRadius = 22 + glowSize
        glow.layer?.backgroundColor = .clear
        glow.layer?.borderColor = NSColor(red: 1.0, green: 0.15, blue: 0.15, alpha: 0.4).cgColor
        glow.layer?.borderWidth = 3
        glow.layer?.shadowColor = NSColor(red: 1.0, green: 0.1, blue: 0.1, alpha: 1.0).cgColor
        glow.layer?.shadowRadius = 20
        glow.layer?.shadowOpacity = 0.6
        glow.layer?.shadowOffset = .zero
        glow.layer?.masksToBounds = false
        root.addSubview(glow, positioned: .below, relativeTo: glass)

        let glowPulse = CABasicAnimation(keyPath: "shadowOpacity")
        glowPulse.fromValue = 0.3
        glowPulse.toValue = 0.8
        glowPulse.duration = 1.4
        glowPulse.autoreverses = true
        glowPulse.repeatCount = .infinity
        glowPulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        glow.layer?.add(glowPulse, forKey: "glowPulse")

        let borderPulse = CABasicAnimation(keyPath: "borderColor")
        borderPulse.fromValue = NSColor(red: 1.0, green: 0.15, blue: 0.15, alpha: 0.2).cgColor
        borderPulse.toValue = NSColor(red: 1.0, green: 0.15, blue: 0.15, alpha: 0.6).cgColor
        borderPulse.duration = 1.4
        borderPulse.autoreverses = true
        borderPulse.repeatCount = .infinity
        borderPulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        glow.layer?.add(borderPulse, forKey: "borderPulse")

        // Big percentage
        let percentLabel = NSTextField(labelWithString: "\(batteryPercent)%")
        percentLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 56, weight: .bold)
        percentLabel.textColor = NSColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0)
        percentLabel.alignment = .center
        percentLabel.frame = NSRect(x: 0, y: cardH - 90, width: cardW, height: 65)
        glass.addSubview(percentLabel)

        // Pulsing percentage text
        let textPulse = CABasicAnimation(keyPath: "opacity")
        textPulse.fromValue = 0.75
        textPulse.toValue = 1.0
        textPulse.duration = 1.0
        textPulse.autoreverses = true
        textPulse.repeatCount = .infinity
        textPulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        percentLabel.layer?.add(textPulse, forKey: "textPulse")

        let message = NSTextField(labelWithString: "Battery critical — plug in now")
        message.font = NSFont.systemFont(ofSize: 16, weight: .medium)
        message.textColor = NSColor(white: 1.0, alpha: 0.75)
        message.alignment = .center
        message.frame = NSRect(x: 0, y: cardH - 125, width: cardW, height: 28)
        glass.addSubview(message)

        let btn = GlassButton(title: "Dismiss", target: self, action: #selector(dismiss))
        btn.frame = NSRect(x: (cardW - 130) / 2, y: 22, width: 130, height: 38)
        glass.addSubview(btn)

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func dismiss() {
        NSApplication.shared.terminate(nil)
    }

    @objc func closeIfCharging() {
        if Self.isCharging() {
            NSApplication.shared.terminate(nil)
        }
    }

    static func isCharging() -> Bool {
        let process = Process()
        let output = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = ["-g", "batt"]
        process.standardOutput = output
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return false
        }

        guard process.terminationStatus == 0 else {
            return false
        }

        let data = output.fileHandleForReading.readDataToEndOfFile()
        let status = String(data: data, encoding: .utf8) ?? ""
        return status.contains("AC Power")
    }
}

class GlassButton: NSButton {
    var hovered = false

    override var allowsVibrancy: Bool {
        false
    }

    convenience init(title: String, target: AnyObject, action: Selector) {
        self.init(frame: .zero)
        self.title = title
        self.target = target
        self.action = action
        self.isBordered = false
        self.wantsLayer = true
        self.appearance = NSAppearance(named: .darkAqua)
        self.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        let area = NSTrackingArea(
            rect: .zero,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self
        )
        addTrackingArea(area)
    }

    override func draw(_ dirtyRect: NSRect) {
        let buttonRect = bounds.insetBy(dx: 0.5, dy: 0.5)
        let background = hovered
            ? NSColor(white: 1.0, alpha: 0.28)
            : NSColor(white: 1.0, alpha: 0.18)
        let border = NSColor(white: 1.0, alpha: 0.55)
        let path = NSBezierPath(roundedRect: buttonRect, xRadius: 12, yRadius: 12)

        background.setFill()
        path.fill()
        border.setStroke()
        path.lineWidth = 1
        path.stroke()

        let style = NSMutableParagraphStyle()
        style.alignment = .center
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font ?? NSFont.systemFont(ofSize: 14, weight: .medium),
            .foregroundColor: NSColor.white,
            .paragraphStyle: style
        ]
        let size = title.size(withAttributes: attrs)
        let textRect = NSRect(
            x: 0,
            y: (bounds.height - size.height) / 2,
            width: bounds.width,
            height: size.height
        )
        title.draw(in: textRect, withAttributes: attrs)
    }

    override func mouseEntered(with event: NSEvent) {
        hovered = true
        needsDisplay = true
    }

    override func mouseExited(with event: NSEvent) {
        hovered = false
        needsDisplay = true
    }
}

let percent = CommandLine.arguments.count > 1 ? (Int(CommandLine.arguments[1]) ?? 0) : 0
let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AlertDelegate(batteryPercent: percent)
app.delegate = delegate
app.run()
