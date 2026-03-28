import AppKit

enum IconRenderer {
    private static let size = NSSize(width: 18, height: 18)

    private struct BarGeometry {
        let x: CGFloat
        let y: CGFloat
        let width: CGFloat
        let height: CGFloat
    }

    private struct BarPalette {
        let trackColor: NSColor
        let fillColor: NSColor?
    }

    private static let semanticBarGeometries: [BarGeometry] = [
        .init(x: 1.5, y: 2, width: 3.0, height: 5.5),
        .init(x: 5.5, y: 2, width: 3.0, height: 8.0),
        .init(x: 9.5, y: 2, width: 3.0, height: 11.0),
        .init(x: 13.5, y: 2, width: 3.0, height: 14.0)
    ]

    private static let segmentedPipelineGeometries: [BarGeometry] = [
        .init(x: 1.5, y: 4, width: 3.0, height: 10.0),
        .init(x: 5.5, y: 4, width: 3.0, height: 10.0),
        .init(x: 9.5, y: 4, width: 3.0, height: 10.0),
        .init(x: 13.5, y: 4, width: 3.0, height: 10.0)
    ]

    static func makeIcon(
        state: ToolbarVisualState,
        displayMode: MenuBarDisplayMode,
        colorMode: MenuBarColorMode) -> NSImage
    {
        let image = NSImage(size: size)
        image.lockFocus()

        let alphaMultiplier: CGFloat = state.isDimmed ? 0.5 : 1.0
        switch displayMode {
        case .semanticBars:
            drawBars(
                geometries: semanticBarGeometries,
                states: state.bars,
                colorMode: colorMode,
                alphaMultiplier: alphaMultiplier)
        case .segmentedPipeline:
            drawBars(
                geometries: segmentedPipelineGeometries,
                states: state.bars,
                colorMode: colorMode,
                alphaMultiplier: alphaMultiplier)
        }

        switch state.overlay {
        case .none:
            break
        case .offlineSlash:
            drawOfflineSlash(colorMode: colorMode, alphaMultiplier: alphaMultiplier)
        case .watchedTargetBadge:
            drawWatchedTargetBadge(colorMode: colorMode, alphaMultiplier: alphaMultiplier)
        }

        image.unlockFocus()
        image.isTemplate = colorMode == .monochrome
        return image
    }

    private static func drawBars(
        geometries: [BarGeometry],
        states: [ToolbarBarVisualState],
        colorMode: MenuBarColorMode,
        alphaMultiplier: CGFloat)
    {
        for (geometry, state) in zip(geometries, states) {
            let rect = CGRect(x: geometry.x, y: geometry.y, width: geometry.width, height: geometry.height)
            drawBar(rect: rect, state: state, colorMode: colorMode, alphaMultiplier: alphaMultiplier)
        }
    }

    private static func drawBar(
        rect: CGRect,
        state: ToolbarBarVisualState,
        colorMode: MenuBarColorMode,
        alphaMultiplier: CGFloat)
    {
        let cornerRadius = min(rect.width, rect.height) / 2
        let trackPath = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
        let palette = palette(for: state.tone, colorMode: colorMode, alphaMultiplier: alphaMultiplier)

        palette.trackColor.setFill()
        trackPath.fill()

        let fillFraction = CGFloat(state.fillFraction)

        guard fillFraction > 0, let fillColor = palette.fillColor else { return }

        let fillRect = CGRect(
            x: rect.minX,
            y: rect.minY,
            width: rect.width,
            height: rect.height * fillFraction)

        NSGraphicsContext.current?.saveGraphicsState()
        trackPath.addClip()
        fillColor.setFill()
        NSBezierPath(rect: fillRect).fill()
        NSGraphicsContext.current?.restoreGraphicsState()
    }

    private static func palette(
        for tone: ToolbarBarTone,
        colorMode: MenuBarColorMode,
        alphaMultiplier: CGFloat) -> BarPalette
    {
        switch colorMode {
        case .monochrome:
            let trackAlpha: CGFloat = {
                switch tone {
                case .healthy:
                    0.22
                case .degraded:
                    0.24
                case .failed:
                    0.42
                case .pending:
                    0.22
                case .unavailable:
                    0.16
                }
            }() * alphaMultiplier

            let fillColor: NSColor? = switch tone {
            case .healthy, .degraded, .failed:
                NSColor.labelColor.withAlphaComponent(alphaMultiplier)
            case .pending:
                NSColor.labelColor.withAlphaComponent(0.38 * alphaMultiplier)
            case .unavailable:
                NSColor.tertiaryLabelColor.withAlphaComponent(0.28 * alphaMultiplier)
            }

            return BarPalette(
                trackColor: NSColor.labelColor.withAlphaComponent(trackAlpha),
                fillColor: fillColor)

        case .mutedAccent:
            switch tone {
            case .healthy:
                return BarPalette(
                    trackColor: NSColor.labelColor.withAlphaComponent(0.20 * alphaMultiplier),
                    fillColor: NSColor.labelColor.withAlphaComponent(alphaMultiplier))
            case .degraded:
                return BarPalette(
                    trackColor: NSColor.systemOrange.withAlphaComponent(0.28 * alphaMultiplier),
                    fillColor: NSColor.systemOrange.withAlphaComponent(0.84 * alphaMultiplier))
            case .failed:
                return BarPalette(
                    trackColor: NSColor.systemRed.withAlphaComponent(0.68 * alphaMultiplier),
                    fillColor: NSColor.systemRed.withAlphaComponent(0.88 * alphaMultiplier))
            case .pending:
                return BarPalette(
                    trackColor: NSColor.secondaryLabelColor.withAlphaComponent(0.22 * alphaMultiplier),
                    fillColor: NSColor.secondaryLabelColor.withAlphaComponent(0.34 * alphaMultiplier))
            case .unavailable:
                return BarPalette(
                    trackColor: NSColor.tertiaryLabelColor.withAlphaComponent(0.28 * alphaMultiplier),
                    fillColor: NSColor.tertiaryLabelColor.withAlphaComponent(0.28 * alphaMultiplier))
            }
        }
    }

    private static func drawOfflineSlash(colorMode: MenuBarColorMode, alphaMultiplier: CGFloat) {
        let path = NSBezierPath()
        path.lineWidth = 1.5
        path.move(to: CGPoint(x: 2, y: 15.5))
        path.line(to: CGPoint(x: 16, y: 2.5))
        path.lineCapStyle = .round
        let color = switch colorMode {
        case .monochrome:
            NSColor.labelColor.withAlphaComponent(0.9 * alphaMultiplier)
        case .mutedAccent:
            NSColor.systemRed.withAlphaComponent(0.88 * alphaMultiplier)
        }
        color.setStroke()
        path.stroke()
    }

    private static func drawWatchedTargetBadge(colorMode: MenuBarColorMode, alphaMultiplier: CGFloat) {
        let badgeRect = CGRect(x: 13.25, y: 13.25, width: 3.5, height: 3.5)
        let path = NSBezierPath(ovalIn: badgeRect)
        let color = switch colorMode {
        case .monochrome:
            NSColor.labelColor.withAlphaComponent(alphaMultiplier)
        case .mutedAccent:
            NSColor.systemBlue.withAlphaComponent(0.85 * alphaMultiplier)
        }
        color.setFill()
        path.fill()
    }
}
