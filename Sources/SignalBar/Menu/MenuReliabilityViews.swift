import SignalBarCore
import SwiftUI

struct MenuReliabilityHistoryView: View {
    let timeline: MetricTimeline
    let breakdown: MetricBreakdown?
    @Binding var hoveredDate: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            MenuReliabilityStripView(timeline: timeline, hoveredDate: $hoveredDate)
            Divider()
            MenuReliabilityDetailSectionView(breakdown: breakdown, hoveredDate: $hoveredDate)
        }
    }
}

private struct MenuReliabilityStripView: View {
    let timeline: MetricTimeline
    @Binding var hoveredDate: Date?

    private var activePoint: MetricPoint? {
        if let hoveredDate {
            return timeline.points.min { lhs, rhs in
                abs(lhs.date.timeIntervalSince(hoveredDate)) < abs(rhs.date.timeIntervalSince(hoveredDate))
            }
        }
        return timeline.points.last(where: { $0.value != nil }) ?? timeline.points.last
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { geometry in
                let metrics = layoutMetrics(for: geometry.size.width, bucketCount: timeline.points.count)
                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(MenuPalette.plotBackground)

                    VStack(spacing: 0) {
                        ForEach(0 ..< 4, id: \.self) { _ in
                            Spacer(minLength: 0)
                            Rectangle()
                                .fill(MenuPalette.grid)
                                .frame(height: 1)
                        }
                    }

                    ForEach(Array(timeline.points.enumerated()), id: \.offset) { index, point in
                        let frame = bucketFrame(index: index, metrics: metrics, height: geometry.size.height)
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(Color.white.opacity(0.05))
                            if let value = point.value {
                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                    .fill(metricColor(for: point.qualityBand))
                                    .frame(height: max(2, frame.height * CGFloat(max(0, min(100, value)) / 100)))
                            } else {
                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                    .fill(Color.secondary.opacity(0.20))
                            }
                        }
                        .frame(width: frame.width, height: frame.height)
                        .position(x: frame.midX, y: frame.midY)
                        .overlay {
                            if point.id == activePoint?.id {
                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                    .stroke(Color.white.opacity(0.8), lineWidth: 1.2)
                            }
                        }
                    }

                    if !timeline.points.contains(where: { $0.value != nil }) {
                        VStack(spacing: 4) {
                            Text("No reliability samples yet")
                                .font(.caption)
                                .fontWeight(.semibold)
                            Text("SignalBar will populate the success strip once probes collect enough data.")
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
                    axisTag("100%")
                        .padding(8)
                }
                .overlay(alignment: .bottomLeading) {
                    axisTag("0%")
                        .padding(8)
                }
            }
            .frame(height: 120)

            HStack {
                Text(MenuFormatters.axisTime.string(from: timeline.points.first?.date ?? .now))
                Spacer(minLength: 8)
                Text(MenuFormatters.axisTime.string(from: timeline.points.last?.date ?? .now))
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
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

    private func nearestDate(for x: CGFloat?, width: CGFloat) -> Date? {
        guard let x else { return nil }
        let metrics = layoutMetrics(for: width, bucketCount: timeline.points.count)
        let nearestIndex = timeline.points.indices.min { lhs, rhs in
            abs(bucketFrame(index: lhs, metrics: metrics, height: 1).midX - x) < abs(bucketFrame(
                index: rhs,
                metrics: metrics,
                height: 1).midX - x)
        }
        return nearestIndex.map { timeline.points[$0].date }
    }

    private func layoutMetrics(for width: CGFloat,
                               bucketCount: Int) -> (horizontalInset: CGFloat, gap: CGFloat, bucketWidth: CGFloat)
    {
        let horizontalInset: CGFloat = 8
        let gap: CGFloat = 2
        guard bucketCount > 0 else {
            return (horizontalInset, gap, width - (horizontalInset * 2))
        }
        let usableWidth = max(1, width - (horizontalInset * 2) - (CGFloat(bucketCount - 1) * gap))
        return (horizontalInset, gap, usableWidth / CGFloat(bucketCount))
    }

    private func bucketFrame(
        index: Int,
        metrics: (horizontalInset: CGFloat, gap: CGFloat, bucketWidth: CGFloat),
        height: CGFloat) -> CGRect
    {
        let x = metrics.horizontalInset + CGFloat(index) * (metrics.bucketWidth + metrics.gap)
        let y: CGFloat = 8
        let bucketHeight = max(1, height - 16)
        return CGRect(x: x, y: y, width: metrics.bucketWidth, height: bucketHeight)
    }
}

private struct MenuReliabilityDetailSectionView: View {
    let breakdown: MetricBreakdown?
    @Binding var hoveredDate: Date?

    private var currentDetail: MetricBucketDetail? {
        guard let breakdown else { return nil }
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

    private var contributionSummary: ReliabilityContributionSummary {
        HistoryModeDisplayLogic.reliabilityContributionSummary(for: currentContributions)
    }

    private var issueContributions: [MetricBucketContribution] {
        HistoryModeDisplayLogic.reliabilityIssueContributions(from: currentContributions)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("Reliability detail")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 8)
                Text(detailHeaderText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if let currentDetail {
                Text(HistoryModeDisplayLogic.reliabilityValueText(currentDetail.aggregateValue))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(aggregateColor(for: currentDetail.aggregateValue))
                Text(distributionLine)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                if currentContributions.isEmpty {
                    Text("No per-target reliability evidence yet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if issueContributions.isEmpty {
                    Text("All reporting targets succeeded in this bucket.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(issueContributions, id: \.id) { contribution in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(metricColor(for: contribution.qualityBand))
                                    .frame(width: 7, height: 7)
                                Text(contribution.label)
                                    .font(.caption)
                                    .lineLimit(1)
                                Spacer(minLength: 8)
                                Text(issueText(for: contribution))
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(metricColor(for: contribution.qualityBand))
                            }
                        }
                    }
                }
            } else {
                Text("No reliability history yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var detailHeaderText: String {
        guard let date = currentDetail?.date else { return "latest" }
        return MenuFormatters.historyTime.string(from: date)
    }

    private var distributionLine: String {
        let parts = [
            contributionSummary.healthyCount > 0 ? "\(contributionSummary.healthyCount) healthy" : nil,
            contributionSummary.degradedCount > 0 ? "\(contributionSummary.degradedCount) degraded" : nil,
            contributionSummary.failingCount > 0 ? "\(contributionSummary.failingCount) failing" : nil,
            contributionSummary.unavailableCount > 0 ? "\(contributionSummary.unavailableCount) unavailable" : nil
        ].compactMap(\.self)

        if parts.isEmpty {
            return "No reporting targets in this bucket"
        }
        return parts.joined(separator: " · ")
    }

    private func issueText(for contribution: MetricBucketContribution) -> String {
        if let failureText = contribution.failureText {
            return failureText
        }
        if let value = contribution.value {
            return HistoryModeDisplayLogic.reliabilityValueText(value)
        }
        return "No data"
    }

    private func aggregateColor(for value: Double?) -> Color {
        guard let value else { return .secondary }
        return metricColor(for: qualityBand(for: .reliability, value: value))
    }
}
