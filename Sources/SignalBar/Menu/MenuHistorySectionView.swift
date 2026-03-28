import Observation
import SignalBarCore
import SwiftUI

struct MenuHistorySectionView: View {
    @Bindable var store: HealthStore
    @State private var hoveredDate: Date?

    private var snapshot: HistorySnapshot {
        store.historySnapshot
    }

    private var selectedMetric: HistoryMetric {
        store.historyMetric
    }

    private var selectedTimeline: MetricTimeline? {
        snapshot.timeline(for: selectedMetric)
    }

    private var selectedBreakdown: MetricBreakdown? {
        snapshot.breakdown(for: selectedMetric)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            headerRow
            metricSelectorRow
            windowSelectorRow
            summaryRow

            if selectedMetric == .overview {
                MenuOverviewTimelineGraphView(snapshot: snapshot)
            } else if selectedMetric == .reliability,
                      let selectedTimeline
            {
                MenuReliabilityHistoryView(
                    timeline: selectedTimeline,
                    breakdown: selectedBreakdown,
                    hoveredDate: $hoveredDate)
            } else if let selectedTimeline {
                MenuNumericHistoryView(
                    metric: selectedMetric,
                    timeline: selectedTimeline,
                    breakdown: selectedBreakdown,
                    hoveredDate: $hoveredDate)
            }
        }
    }

    private var headerRow: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Network history")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer(minLength: 8)
            Text(snapshot.window.displayName)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
        }
    }

    private var metricSelectorRow: some View {
        HStack(spacing: 6) {
            ForEach(HistoryMetric.allCases, id: \.self) { metric in
                Button(metric.displayName) {
                    hoveredDate = nil
                    store.setHistoryMetric(metric)
                }
                .buttonStyle(MenuSegmentButtonStyle(isSelected: metric == selectedMetric))
                .fixedSize(horizontal: true, vertical: false)
            }
            Spacer(minLength: 0)
        }
    }

    private var windowSelectorRow: some View {
        HStack(spacing: 6) {
            ForEach(HistoryWindow.allCases, id: \.self) { window in
                Button(window.displayName) {
                    hoveredDate = nil
                    store.setTimelineWindow(window)
                }
                .buttonStyle(MenuSegmentButtonStyle(isSelected: window == snapshot.window, compact: true))
                .fixedSize(horizontal: true, vertical: false)
            }
            Spacer(minLength: 0)
        }
    }

    private var summaryRow: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(selectedMetric.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)
                Text(detailLine)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            Spacer(minLength: 8)
            Text(valueLine)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(valueColor)
                .monospacedDigit()
                .lineLimit(1)
        }
    }

    private var detailLine: String {
        if let hoveredDetail = hoveredBucketDetail {
            return "\(MenuFormatters.historyTime.string(from: hoveredDetail.date)) · \(detailMetricText(for: hoveredDetail))"
        }
        if let timeline = selectedTimeline,
           let medianValue = timeline.medianValue
        {
            return "median \(summaryValueText(medianValue, metric: timeline.metric))"
        }
        if selectedMetric == .overview {
            return "link, dns, internet, and quality over time"
        }
        return "collecting enough data for a stable reading"
    }

    private func detailMetricText(for detail: MetricBucketDetail) -> String {
        if let aggregateValue = detail.aggregateValue {
            if detail.metric == .reliability {
                return HistoryModeDisplayLogic.reliabilityValueText(aggregateValue)
            }
            return "\(detail.metric.displayName) \(formattedMetricValue(aggregateValue, metric: detail.metric))"
        }
        return "No data"
    }

    private var valueLine: String {
        if selectedMetric == .overview {
            return snapshot.window.displayName
        }
        if let hoveredDetail = hoveredBucketDetail,
           let aggregateValue = hoveredDetail.aggregateValue
        {
            return summaryValueText(aggregateValue, metric: hoveredDetail.metric)
        }
        if let timeline = selectedTimeline,
           let latestValue = timeline.latestValue
        {
            return summaryValueText(latestValue, metric: timeline.metric)
        }
        return "No data"
    }

    private var valueColor: Color {
        if let hoveredDetail = hoveredBucketDetail,
           let aggregateValue = hoveredDetail.aggregateValue
        {
            return color(for: qualityBand(for: hoveredDetail.metric, value: aggregateValue))
        }
        if let timeline = selectedTimeline,
           let latestBand = timeline.points.last(where: { $0.value != nil })?.qualityBand
        {
            return color(for: latestBand)
        }
        return .secondary
    }

    private var hoveredBucketDetail: MetricBucketDetail? {
        guard let breakdown = selectedBreakdown else { return nil }
        let fallbackDetail = breakdown.bucketDetails.last(where: {
            $0.aggregateValue != nil || !$0.contributions.isEmpty
        }) ?? breakdown.bucketDetails.last
        guard let hoveredDate else { return fallbackDetail }
        return breakdown.bucketDetails.min { lhs, rhs in
            abs(lhs.date.timeIntervalSince(hoveredDate)) < abs(rhs.date.timeIntervalSince(hoveredDate))
        }
    }

    private func color(for band: MetricQualityBand) -> Color {
        metricColor(for: band)
    }

    private func summaryValueText(_ value: Double, metric: HistoryMetric) -> String {
        if metric == .reliability {
            return HistoryModeDisplayLogic.reliabilityValueText(value)
        }
        return formattedMetricValue(value, metric: metric)
    }
}

private struct MenuSegmentButtonStyle: ButtonStyle {
    let isSelected: Bool
    var compact: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .fontWeight(isSelected ? .semibold : .medium)
            .lineLimit(1)
            .padding(.horizontal, compact ? 8 : 10)
            .padding(.vertical, 5)
            .foregroundStyle(foregroundColor(isPressed: configuration.isPressed))
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(backgroundColor(isPressed: configuration.isPressed)))
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(borderColor, lineWidth: 1))
            .contentShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
    }

    private func backgroundColor(isPressed: Bool) -> Color {
        if isSelected {
            return Color.accentColor.opacity(isPressed ? 0.24 : 0.18)
        }
        return Color.white.opacity(isPressed ? 0.08 : 0.05)
    }

    private func foregroundColor(isPressed: Bool) -> Color {
        if isSelected {
            return .accentColor
        }
        return isPressed ? .primary : .secondary
    }

    private var borderColor: Color {
        isSelected ? Color.accentColor.opacity(0.30) : Color.primary.opacity(0.08)
    }
}

struct MenuNumericHistoryView: View {
    let metric: HistoryMetric
    let timeline: MetricTimeline
    let breakdown: MetricBreakdown?
    @Binding var hoveredDate: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            MenuMetricGraphView(timeline: timeline, hoveredDate: $hoveredDate)
            if let breakdown, !breakdown.bucketDetails.isEmpty {
                Divider()
                MenuMetricBreakdownSectionView(
                    metric: metric,
                    breakdown: breakdown,
                    hoveredDate: $hoveredDate)
            }
        }
    }
}
