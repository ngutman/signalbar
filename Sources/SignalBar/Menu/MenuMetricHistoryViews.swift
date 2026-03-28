import SignalBarCore
import SwiftUI

struct MenuMetricGraphView: View {
    let timeline: MetricTimeline
    @Binding var hoveredDate: Date?

    private var validPoints: [MetricPoint] {
        MetricGraphSeriesLayout.visiblePoints(from: timeline.points)
    }

    private var highlightedPoint: MetricPoint? {
        if let hoveredDate {
            return timeline.points.min { lhs, rhs in
                abs(lhs.date.timeIntervalSince(hoveredDate)) < abs(rhs.date.timeIntervalSince(hoveredDate))
            }
        }
        return timeline.points.last(where: { $0.value != nil })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { geometry in
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(MenuPalette.plotBackground)

                    thresholdBands(height: geometry.size.height)

                    gridLines(height: geometry.size.height)

                    ForEach(Array(drawnSegments(in: geometry.size).enumerated()), id: \.offset) { _, segment in
                        Path { path in
                            path.move(to: segment.start)
                            path.addLine(to: segment.end)
                        }
                        .stroke(segment.color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    }

                    ForEach(failureMarkers(in: geometry.size), id: \.x) { marker in
                        Rectangle()
                            .fill(MenuPalette.bad.opacity(0.95))
                            .frame(width: 2, height: 10)
                            .position(x: marker.x, y: geometry.size.height - 6)
                    }

                    if let hoveredDate {
                        let x = xPosition(for: hoveredDate, width: geometry.size.width)
                        Rectangle()
                            .fill(Color.white.opacity(0.35))
                            .frame(width: 1, height: geometry.size.height)
                            .position(x: x, y: geometry.size.height / 2)
                    }

                    ForEach(drawnPoints(in: geometry.size), id: \.id) { point in
                        ZStack {
                            if point.isHighlighted {
                                Circle()
                                    .stroke(Color.white.opacity(0.85), lineWidth: 1)
                                    .frame(width: 12, height: 12)
                            }
                            Circle()
                                .fill(point.color)
                                .frame(width: point.isHighlighted ? 8 : 6, height: point.isHighlighted ? 8 : 6)
                        }
                        .position(point.position)
                    }

                    if validPoints.count < 2 {
                        VStack(spacing: 4) {
                            Text(validPoints.isEmpty ? "No samples yet" : "Waiting for more samples")
                                .font(.caption)
                                .fontWeight(.semibold)
                            Text("SignalBar will draw a trend once live probes collect enough data.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 16)
                    }

                    MouseLocationReader { location in
                        hoveredDate = nearestDate(for: location?.x, width: geometry.size.width)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                }
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(MenuPalette.plotBorder, lineWidth: 1))
                .overlay(alignment: .topLeading) {
                    axisTag(topAxisLabel)
                        .padding(8)
                }
                .overlay(alignment: .bottomLeading) {
                    axisTag(bottomAxisLabel)
                        .padding(8)
                }
            }
            .frame(height: 120)

            HStack {
                Text(startAxisTime)
                Spacer(minLength: 8)
                Text(endAxisTime)
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
    }

    private struct DrawnPoint {
        let id: Double
        let position: CGPoint
        let color: Color
        let isHighlighted: Bool
    }

    private struct DrawnSegment {
        let start: CGPoint
        let end: CGPoint
        let color: Color
    }

    private struct FailureMarker {
        let x: CGFloat
    }

    private var topAxisLabel: String {
        switch timeline.metric {
        case .ping, .jitter:
            "\(Int(upperBound.rounded())) ms"
        case .reliability:
            "100%"
        case .overview:
            ""
        }
    }

    private var bottomAxisLabel: String {
        switch timeline.metric {
        case .ping, .jitter:
            "0 ms"
        case .reliability:
            "0%"
        case .overview:
            ""
        }
    }

    private var startAxisTime: String {
        MenuFormatters.axisTime.string(from: timeline.points.first?.date ?? .now)
    }

    private var endAxisTime: String {
        MenuFormatters.axisTime.string(from: timeline.points.last?.date ?? .now)
    }

    private var upperBound: Double {
        metricUpperBound(metric: timeline.metric, maxValue: timeline.points.compactMap(\.value).max() ?? 0)
    }

    private func axisTag(_ text: String) -> some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.black.opacity(0.18)))
            .foregroundStyle(.secondary)
    }

    private func thresholdBands(height: CGFloat) -> some View {
        VStack(spacing: 0) {
            ForEach(thresholdBandModels(), id: \.id) { band in
                Rectangle()
                    .fill(band.color)
                    .frame(height: height * band.heightFraction)
            }
        }
    }

    private func gridLines(height: CGFloat) -> some View {
        VStack(spacing: 0) {
            ForEach(0 ..< 4, id: \.self) { _ in
                Spacer(minLength: 0)
                Rectangle()
                    .fill(MenuPalette.grid)
                    .frame(height: 1)
            }
        }
    }

    private func drawnPoints(in size: CGSize) -> [DrawnPoint] {
        let highlightedID = highlightedPoint?.id
        return timeline.points.compactMap { point in
            guard let value = point.value else { return nil }
            return DrawnPoint(
                id: point.id,
                position: CGPoint(
                    x: xPosition(for: point.date, width: size.width),
                    y: yPosition(for: value, height: size.height)),
                color: metricColor(for: point.qualityBand),
                isHighlighted: point.id == highlightedID)
        }
    }

    private func drawnSegments(in size: CGSize) -> [DrawnSegment] {
        MetricGraphSeriesLayout.connectedPairs(from: timeline.points).compactMap { lhs, rhs in
            guard let lhsValue = lhs.value, let rhsValue = rhs.value else { return nil }
            return DrawnSegment(
                start: CGPoint(
                    x: xPosition(for: lhs.date, width: size.width),
                    y: yPosition(for: lhsValue, height: size.height)),
                end: CGPoint(
                    x: xPosition(for: rhs.date, width: size.width),
                    y: yPosition(for: rhsValue, height: size.height)),
                color: metricColor(for: rhs.qualityBand))
        }
    }

    private func failureMarkers(in size: CGSize) -> [FailureMarker] {
        timeline.points
            .filter(\.hadFailure)
            .map { FailureMarker(x: xPosition(for: $0.date, width: size.width)) }
    }

    private func nearestDate(for x: CGFloat?, width: CGFloat) -> Date? {
        guard let x else { return nil }
        return validPoints.min { lhs, rhs in
            abs(xPosition(for: lhs.date, width: width) - x) < abs(xPosition(for: rhs.date, width: width) - x)
        }?.date
    }

    private func xPosition(for date: Date, width: CGFloat) -> CGFloat {
        let totalDuration = timeline.points.last?.date.timeIntervalSince(timeline.points.first?.date ?? date) ?? 0
        guard totalDuration > 0, let firstDate = timeline.points.first?.date else { return width / 2 }
        let elapsed = date.timeIntervalSince(firstDate)
        return max(8, min(width - 8, CGFloat(elapsed / totalDuration) * (width - 16) + 8))
    }

    private func yPosition(for value: Double, height: CGFloat) -> CGFloat {
        guard upperBound > 0 else { return height / 2 }
        let normalized = max(0, min(1, value / upperBound))
        return height - (CGFloat(normalized) * (height - 16)) - 8
    }

    private func thresholdBandModels() -> [ThresholdBandModel] {
        let ranges: [(String, Double, Double, Color)] = switch timeline.metric {
        case .ping:
            [
                ("bad", 250, upperBound, MenuPalette.bad.opacity(0.14)),
                ("degraded", 120, min(250, upperBound), MenuPalette.degraded.opacity(0.12)),
                ("okay", 60, min(120, upperBound), MenuPalette.okay.opacity(0.10)),
                ("good", 0, min(60, upperBound), MenuPalette.good.opacity(0.10))
            ]
        case .jitter:
            [
                ("bad", 60, upperBound, MenuPalette.bad.opacity(0.14)),
                ("degraded", 30, min(60, upperBound), MenuPalette.degraded.opacity(0.12)),
                ("okay", 15, min(30, upperBound), MenuPalette.okay.opacity(0.10)),
                ("good", 0, min(15, upperBound), MenuPalette.good.opacity(0.10))
            ]
        case .reliability:
            [
                ("good", 99, 100, MenuPalette.good.opacity(0.10)),
                ("okay", 95, 99, MenuPalette.okay.opacity(0.10)),
                ("degraded", 80, 95, MenuPalette.degraded.opacity(0.12)),
                ("bad", 0, 80, MenuPalette.bad.opacity(0.14))
            ]
        case .overview:
            []
        }

        return ranges.compactMap { id, lower, upper, color in
            let clampedLower = max(0, min(lower, upperBound))
            let clampedUpper = max(0, min(upper, upperBound))
            guard clampedUpper > clampedLower, upperBound > 0 else { return nil }
            return ThresholdBandModel(
                id: id,
                heightFraction: CGFloat((clampedUpper - clampedLower) / upperBound),
                color: color)
        }
    }

    private struct ThresholdBandModel {
        let id: String
        let heightFraction: CGFloat
        let color: Color
    }
}

struct MenuMetricBreakdownSectionView: View {
    let metric: HistoryMetric
    let breakdown: MetricBreakdown
    @Binding var hoveredDate: Date?

    private var currentDetail: MetricBucketDetail? {
        let fallbackDetail = breakdown.bucketDetails.last(where: {
            $0.aggregateValue != nil || !$0.contributions.isEmpty
        }) ?? breakdown.bucketDetails.last
        guard let hoveredDate else { return fallbackDetail }
        return breakdown.bucketDetails.min { lhs, rhs in
            abs(lhs.date.timeIntervalSince(hoveredDate)) < abs(rhs.date.timeIntervalSince(hoveredDate))
        }
    }

    private var currentContributions: [MetricBucketContribution] {
        currentDetail?.contributions ?? []
    }

    private var hasTrend: Bool {
        breakdown.series.contains { series in
            series.points.compactMap(\.value).count >= 2
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("Contributors")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 8)
                Text(detailHeaderText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if hasTrend {
                MenuBreakdownMiniGraphView(
                    metric: metric,
                    breakdown: breakdown,
                    hoveredDate: $hoveredDate)
            }

            if currentContributions.isEmpty {
                Text("No per-target breakdown yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(currentContributions, id: \.id) { contribution in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(seriesColor(for: contribution.label))
                                .frame(width: 7, height: 7)
                            Text(contribution.label)
                                .font(.caption)
                                .lineLimit(1)
                            Spacer(minLength: 8)
                            Text(valueText(for: contribution))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(metricColor(for: contribution.qualityBand))
                                .monospacedDigit()
                        }
                    }
                }
            }
        }
    }

    private var detailHeaderText: String {
        let date = currentDetail?.date ?? breakdown.bucketDetails.last?.date
        guard let date else { return "latest" }
        return MenuFormatters.historyTime.string(from: date)
    }

    private func valueText(for contribution: MetricBucketContribution) -> String {
        if let value = contribution.value {
            return formattedMetricValue(value, metric: metric)
        }
        return contribution.failureText ?? "No data"
    }

    private func seriesColor(for label: String) -> Color {
        let series = breakdown.series
        let index = series.firstIndex(where: { $0.label == label }) ?? 0
        return breakdownSeriesColor(index: index)
    }
}

private struct MenuBreakdownMiniGraphView: View {
    let metric: HistoryMetric
    let breakdown: MetricBreakdown
    @Binding var hoveredDate: Date?

    private var upperBound: Double {
        metricUpperBound(
            metric: metric,
            maxValue: breakdown.series.flatMap { $0.points.compactMap(\.value) }.max() ?? 0)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(MenuPalette.plotBackground)

                VStack(spacing: 0) {
                    ForEach(0 ..< 3, id: \.self) { _ in
                        Spacer(minLength: 0)
                        Rectangle()
                            .fill(MenuPalette.grid)
                            .frame(height: 1)
                    }
                }

                ForEach(Array(breakdown.series.enumerated()), id: \.offset) { index, series in
                    let color = breakdownSeriesColor(index: index)
                    ForEach(Array(segments(for: series, in: geometry.size).enumerated()), id: \.offset) { _, segment in
                        Path { path in
                            path.move(to: segment.start)
                            path.addLine(to: segment.end)
                        }
                        .stroke(
                            color.opacity(0.95),
                            style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
                    }
                }

                if let hoveredDate {
                    let x = xPosition(for: hoveredDate, width: geometry.size.width)
                    Rectangle()
                        .fill(Color.white.opacity(0.35))
                        .frame(width: 1, height: geometry.size.height)
                        .position(x: x, y: geometry.size.height / 2)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(MenuPalette.plotBorder, lineWidth: 1))
            .overlay(alignment: .topLeading) {
                Text(topAxisLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(6)
            }
        }
        .frame(height: 56)
    }

    private var topAxisLabel: String {
        switch metric {
        case .ping, .jitter:
            "\(Int(upperBound.rounded())) ms"
        case .reliability:
            "100%"
        case .overview:
            ""
        }
    }

    private func segments(for series: MetricBreakdownSeries, in size: CGSize) -> [(start: CGPoint, end: CGPoint)] {
        MetricGraphSeriesLayout.connectedPairs(from: series.points).compactMap { lhs, rhs in
            guard let lhsValue = lhs.value, let rhsValue = rhs.value else { return nil }
            return (
                start: CGPoint(
                    x: xPosition(for: lhs.date, width: size.width),
                    y: yPosition(for: lhsValue, height: size.height)),
                end: CGPoint(
                    x: xPosition(for: rhs.date, width: size.width),
                    y: yPosition(for: rhsValue, height: size.height)))
        }
    }

    private func xPosition(for date: Date, width: CGFloat) -> CGFloat {
        let referencePoints = breakdown.series.first?.points ?? []
        let totalDuration = referencePoints.last?.date.timeIntervalSince(referencePoints.first?.date ?? date) ?? 0
        guard totalDuration > 0, let firstDate = referencePoints.first?.date else { return width / 2 }
        let elapsed = date.timeIntervalSince(firstDate)
        return max(8, min(width - 8, CGFloat(elapsed / totalDuration) * (width - 16) + 8))
    }

    private func yPosition(for value: Double, height: CGFloat) -> CGFloat {
        guard upperBound > 0 else { return height / 2 }
        let normalized = max(0, min(1, value / upperBound))
        return height - (CGFloat(normalized) * (height - 12)) - 6
    }
}
