import UIKit

/// Protocol for receiving calorie change events from the wheel.
protocol CalorieWheelDelegate: AnyObject {
    func calorieWheelDidChangeCalories(_ calories: Int)
    func calorieWheelDidLongPress()
}

/// Custom UIView that draws and handles the interactive calorie wheel using Core Graphics.
/// Ported from Android's CalorieWheelView (Canvas + Paint → CGContext).
final class CalorieWheelUIView: UIView {

    weak var delegate: CalorieWheelDelegate?

    private let dataStore = CalorieDataStore.shared

    // MARK: - Gradient Colors

    private let gradientColors: [UIColor] = [
        UIColor(hex: 0x4CAF50), // Green
        UIColor(hex: 0x8BC34A), // Light Green
        UIColor(hex: 0xFFEB3B), // Yellow
        UIColor(hex: 0xFF9800), // Orange
        UIColor(hex: 0xF44336), // Red
    ]

    // MARK: - Dimensions (computed on layout)

    private var centerX: CGFloat = 0
    private var centerY: CGFloat = 0
    private var wheelRadius: CGFloat = 0
    private var innerRadius: CGFloat = 0
    private var windowWidth: CGFloat = 0
    private var windowHeight: CGFloat = 0

    // MARK: - Rotation State

    private var currentRotation: CGFloat = 0 // in degrees
    private var previousAngle: CGFloat = 0
    private var lastNotchIndex: Int = -1

    // MARK: - Haptic Generators

    private let lightHaptic = UIImpactFeedbackGenerator(style: .light)
    private let mediumHaptic = UIImpactFeedbackGenerator(style: .medium)

    // MARK: - Long Press

    private var longPressRecognizer: UILongPressGestureRecognizer!

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = .clear
        isMultipleTouchEnabled = false

        longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressRecognizer.minimumPressDuration = 0.5
        addGestureRecognizer(longPressRecognizer)

        lightHaptic.prepare()
        mediumHaptic.prepare()

        updateRotationFromCalories()
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()

        centerX = bounds.midX
        centerY = bounds.midY
        wheelRadius = min(bounds.width, bounds.height) / 2 * 0.85
        innerRadius = wheelRadius * 0.55

        windowWidth = wheelRadius * 0.5
        windowHeight = wheelRadius * 0.25
    }

    // MARK: - Drawing

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }

        drawWheel(ctx)
        drawNotches(ctx)
        drawWindow(ctx)
        drawPointer(ctx)
    }

    private func drawWheel(_ ctx: CGContext) {
        let percentage = dataStore.percentage
        let colorCount = gradientColors.count
        let gradientIndex = Int(percentage * Float(colorCount - 1))
            .clamped(to: 0...(colorCount - 2))

        let startColor = gradientColors[gradientIndex]
        let endColor = gradientColors[min(gradientIndex + 1, colorCount - 1)]
        _ = endColor // used for gradient reference

        // Draw outer wheel with radial gradient
        ctx.saveGState()
        let wheelPath = UIBezierPath(arcCenter: CGPoint(x: centerX, y: centerY),
                                      radius: wheelRadius,
                                      startAngle: 0, endAngle: .pi * 2, clockwise: true)
        wheelPath.addClip()

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let blendedWhite = blendColor(startColor, with: .white, ratio: 0.3)
        let blendedBlack = blendColor(startColor, with: .black, ratio: 0.2)

        if let gradient = CGGradient(colorsSpace: colorSpace,
                                      colors: [blendedWhite.cgColor, startColor.cgColor, blendedBlack.cgColor] as CFArray,
                                      locations: [0, 0.7, 1]) {
            ctx.drawRadialGradient(gradient,
                                   startCenter: CGPoint(x: centerX, y: centerY), startRadius: 0,
                                   endCenter: CGPoint(x: centerX, y: centerY), endRadius: wheelRadius,
                                   options: [.drawsAfterEndLocation])
        }
        ctx.restoreGState()

        // Draw inner circle with dark gradient
        ctx.saveGState()
        let innerPath = UIBezierPath(arcCenter: CGPoint(x: centerX, y: centerY),
                                      radius: innerRadius,
                                      startAngle: 0, endAngle: .pi * 2, clockwise: true)
        innerPath.addClip()

        let darkInner = UIColor(hex: 0x2C2C2C)
        let darkOuter = UIColor(hex: 0x1A1A1A)
        if let innerGradient = CGGradient(colorsSpace: colorSpace,
                                           colors: [darkInner.cgColor, darkOuter.cgColor] as CFArray,
                                           locations: [0, 1]) {
            ctx.drawRadialGradient(innerGradient,
                                   startCenter: CGPoint(x: centerX, y: centerY), startRadius: 0,
                                   endCenter: CGPoint(x: centerX, y: centerY), endRadius: innerRadius,
                                   options: [.drawsAfterEndLocation])
        }
        ctx.restoreGState()

        // Draw rims
        let rimColor = blendColor(startColor, with: .black, ratio: 0.3)
        ctx.setStrokeColor(rimColor.cgColor)
        ctx.setLineWidth(wheelRadius * 0.02)
        ctx.addEllipse(in: CGRect(x: centerX - wheelRadius, y: centerY - wheelRadius,
                                   width: wheelRadius * 2, height: wheelRadius * 2))
        ctx.strokePath()

        ctx.addEllipse(in: CGRect(x: centerX - innerRadius, y: centerY - innerRadius,
                                   width: innerRadius * 2, height: innerRadius * 2))
        ctx.strokePath()
    }

    private func drawNotches(_ ctx: CGContext) {
        let notchCount = dataStore.notchCount
        guard notchCount > 0 else { return }
        let anglePerNotch = 360.0 / CGFloat(notchCount)
        let increment = dataStore.increment

        for i in 0..<notchCount {
            // Angle with rotation offset, -90 to start from top
            let angle = CGFloat(i) * anglePerNotch + currentRotation - 90
            let angleRad = angle * .pi / 180

            let notchInnerRadius = wheelRadius * 0.88
            let notchOuterRadius = wheelRadius * 0.98

            let startX = centerX + notchInnerRadius * cos(angleRad)
            let startY = centerY + notchInnerRadius * sin(angleRad)
            let endX = centerX + notchOuterRadius * cos(angleRad)
            let endY = centerY + notchOuterRadius * sin(angleRad)

            let calorieValue = i * increment
            let isMajorNotch = calorieValue % 500 == 0

            let lineWidth = isMajorNotch ? wheelRadius * 0.02 : wheelRadius * 0.01
            let alpha: CGFloat = isMajorNotch ? 1.0 : 0.7

            ctx.setStrokeColor(UIColor.white.withAlphaComponent(alpha).cgColor)
            ctx.setLineWidth(lineWidth)
            ctx.move(to: CGPoint(x: startX, y: startY))
            ctx.addLine(to: CGPoint(x: endX, y: endY))
            ctx.strokePath()

            // Draw calorie text for major notches
            if isMajorNotch && notchCount <= 100 {
                let textRadius = wheelRadius * 0.75
                let textX = centerX + textRadius * cos(angleRad)
                let textY = centerY + textRadius * sin(angleRad)

                let fontSize = wheelRadius * 0.08
                let text = "\(calorieValue)" as NSString
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: fontSize),
                    .foregroundColor: UIColor.white.withAlphaComponent(0.78),
                ]
                let textSize = text.size(withAttributes: attrs)

                ctx.saveGState()
                ctx.translateBy(x: textX, y: textY)
                ctx.rotate(by: angleRad + .pi / 2)

                text.draw(at: CGPoint(x: -textSize.width / 2, y: -textSize.height / 2),
                          withAttributes: attrs)
                ctx.restoreGState()
            }
        }
    }

    private func drawWindow(_ ctx: CGContext) {
        let windowRect = CGRect(
            x: centerX - windowWidth / 2,
            y: centerY - wheelRadius - windowHeight * 0.3,
            width: windowWidth,
            height: windowHeight * 1.5
        )
        let cornerRadius = windowHeight * 0.3

        // Shadow
        let shadowRect = windowRect.offsetBy(dx: 4, dy: 4)
        let shadowColor = UIColor.black.withAlphaComponent(0.25)
        let shadowPath = UIBezierPath(roundedRect: shadowRect, cornerRadius: cornerRadius)
        ctx.setFillColor(shadowColor.cgColor)
        ctx.addPath(shadowPath.cgPath)
        ctx.fillPath()

        // Window background
        let windowPath = UIBezierPath(roundedRect: windowRect, cornerRadius: cornerRadius)
        ctx.setFillColor(UIColor.white.cgColor)
        ctx.addPath(windowPath.cgPath)
        ctx.fillPath()

        // Window border
        ctx.setStrokeColor(UIColor(hex: 0x333333).cgColor)
        ctx.setLineWidth(wheelRadius * 0.02)
        ctx.addPath(windowPath.cgPath)
        ctx.strokePath()

        // Draw current calorie value
        let currentCalories = dataStore.currentCalories
        let textColor = colorForCalories(currentCalories)
        let fontSize = wheelRadius * 0.18
        let text = "\(currentCalories)" as NSString
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: fontSize),
            .foregroundColor: textColor,
        ]
        let textSize = text.size(withAttributes: attrs)
        let textX = windowRect.midX - textSize.width / 2
        let textY = windowRect.midY - textSize.height / 2 - fontSize * 0.1
        text.draw(at: CGPoint(x: textX, y: textY), withAttributes: attrs)

        // Draw "cal" label
        let labelFontSize = fontSize * 0.35
        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: labelFontSize),
            .foregroundColor: UIColor.gray,
        ]
        let label = "cal" as NSString
        let labelSize = label.size(withAttributes: labelAttrs)
        let labelX = windowRect.midX - labelSize.width / 2
        let labelY = textY + textSize.height - fontSize * 0.05
        label.draw(at: CGPoint(x: labelX, y: labelY), withAttributes: labelAttrs)
    }

    private func drawPointer(_ ctx: CGContext) {
        let pointerHeight = wheelRadius * 0.08
        let pointerWidth = wheelRadius * 0.06

        let pointerTop = centerY - wheelRadius + pointerHeight
        let pointerBase = centerY - wheelRadius - 5

        let path = UIBezierPath()
        path.move(to: CGPoint(x: centerX, y: pointerTop))
        path.addLine(to: CGPoint(x: centerX - pointerWidth / 2, y: pointerBase))
        path.addLine(to: CGPoint(x: centerX + pointerWidth / 2, y: pointerBase))
        path.close()

        ctx.setFillColor(UIColor(hex: 0x333333).cgColor)
        ctx.addPath(path.cgPath)
        ctx.fillPath()
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        previousAngle = getAngle(point)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        let currentAngle = getAngle(point)
        var deltaAngle = currentAngle - previousAngle

        // Handle wrap-around
        if deltaAngle > 180 { deltaAngle -= 360 }
        if deltaAngle < -180 { deltaAngle += 360 }

        currentRotation += deltaAngle
        previousAngle = currentAngle

        updateCaloriesFromRotation()
        setNeedsDisplay()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        snapToNearestNotch()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        snapToNearestNotch()
    }

    @objc private func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .began {
            delegate?.calorieWheelDidLongPress()
        }
    }

    // MARK: - Angle & Rotation Calculations

    private func getAngle(_ point: CGPoint) -> CGFloat {
        let dx = point.x - centerX
        let dy = point.y - centerY
        return atan2(dy, dx) * 180 / .pi
    }

    private func updateCaloriesFromRotation() {
        let notchCount = dataStore.notchCount
        guard notchCount > 0 else { return }
        let anglePerNotch = 360.0 / CGFloat(notchCount)
        let increment = dataStore.increment

        // Normalize rotation to 0-360
        var normalizedRotation = currentRotation.truncatingRemainder(dividingBy: 360)
        if normalizedRotation < 0 { normalizedRotation += 360 }

        // Calculate notch index (inverted — rotation goes opposite to value)
        let notchIndex = Int((360 - normalizedRotation) / anglePerNotch) % notchCount

        let newCalories = notchIndex * increment

        // Haptic feedback when crossing a notch
        if notchIndex != lastNotchIndex {
            let calorieValue = notchIndex * increment
            if calorieValue % 500 == 0 {
                mediumHaptic.impactOccurred()
            } else {
                lightHaptic.impactOccurred()
            }
            lastNotchIndex = notchIndex
        }

        if newCalories != dataStore.currentCalories {
            dataStore.currentCalories = newCalories
            delegate?.calorieWheelDidChangeCalories(newCalories)
        }
    }

    func updateRotationFromCalories() {
        let notchCount = dataStore.notchCount
        guard notchCount > 0 else { return }
        let anglePerNotch = 360.0 / CGFloat(notchCount)
        let increment = dataStore.increment

        let notchIndex = dataStore.currentCalories / increment
        currentRotation = 360 - CGFloat(notchIndex) * anglePerNotch
        lastNotchIndex = notchIndex
    }

    private func snapToNearestNotch() {
        let notchCount = dataStore.notchCount
        guard notchCount > 0 else { return }
        let anglePerNotch = 360.0 / CGFloat(notchCount)

        var normalizedRotation = currentRotation.truncatingRemainder(dividingBy: 360)
        if normalizedRotation < 0 { normalizedRotation += 360 }

        let notchIndex = Int((normalizedRotation + anglePerNotch / 2) / anglePerNotch) % notchCount
        currentRotation = CGFloat(notchIndex) * anglePerNotch

        updateCaloriesFromRotation()
        setNeedsDisplay()

        // Medium haptic on snap confirmation
        mediumHaptic.impactOccurred()
    }

    // MARK: - Refresh

    func refresh() {
        updateRotationFromCalories()
        setNeedsDisplay()
    }

    // MARK: - Color Helpers

    private func colorForCalories(_ calories: Int) -> UIColor {
        let pct = CGFloat(calories) / CGFloat(dataStore.dailyGoal)
        if pct < 0.5 {
            return UIColor(hex: 0x4CAF50)
        } else if pct < 0.75 {
            return UIColor(hex: 0xFF9800)
        } else {
            return UIColor(hex: 0xF44336)
        }
    }

    private func blendColor(_ color1: UIColor, with color2: UIColor, ratio: CGFloat) -> UIColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        color1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        color2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)

        let inverse = 1 - ratio
        return UIColor(red: r1 * inverse + r2 * ratio,
                       green: g1 * inverse + g2 * ratio,
                       blue: b1 * inverse + b2 * ratio,
                       alpha: 1)
    }
}

// MARK: - UIColor Hex Extension

extension UIColor {
    convenience init(hex: Int, alpha: CGFloat = 1.0) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255.0,
            green: CGFloat((hex >> 8) & 0xFF) / 255.0,
            blue: CGFloat(hex & 0xFF) / 255.0,
            alpha: alpha
        )
    }
}

// MARK: - Comparable Clamped Extension

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
