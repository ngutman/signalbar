import SignalBarCore
import SwiftUI

struct MenuOverviewTimelineGraphView: View {
    let snapshot: HistorySnapshot

    private let labelWidth: CGFloat = 52

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(snapshot.layerTimelines) { timeline in
                HStack(spacing: 8) {
                    Text(timeline.layer.displayName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(width: labelWidth, alignment: .leading)
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(MenuPalette.plotBackground)

                            ZStack(alignment: .leading) {
                                ForEach(timeline.segments) { segment in
                                    Rectangle()
                                        .fill(color(for: segment.status))
                                        .frame(
                                            width: segmentWidth(segment, totalWidth: geometry.size.width),
                                            height: geometry.size.height)
                                        .offset(x: segmentOffset(segment, totalWidth: geometry.size.width))
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                            HStack(spacing: 0) {
                                ForEach(0 ..< 4, id: \.self) { index in
                                    Rectangle()
                                        .fill(index == 0 ? .clear : MenuPalette.grid)
                                        .frame(width: 1)
                                    if index < 3 {
                                        Spacer(minLength: 0)
                                    }
                                }
                            }
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(MenuPalette.plotBorder, lineWidth: 1))
                    }
                    .frame(height: 10)
                }
            }

            HStack {
                Text(MenuFormatters.axisTime.string(from: snapshot.startDate))
                Spacer(minLength: 8)
                Text(MenuFormatters.axisTime.string(from: snapshot.endDate))
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
    }

    private func segmentOffset(_ segment: LayerTimelineSegment, totalWidth: CGFloat) -> CGFloat {
        let totalDuration = snapshot.endDate.timeIntervalSince(snapshot.startDate)
        guard totalDuration > 0 else { return 0 }
        let elapsed = segment.startDate.timeIntervalSince(snapshot.startDate)
        return max(0, CGFloat(elapsed / totalDuration) * totalWidth)
    }

    private func segmentWidth(_ segment: LayerTimelineSegment, totalWidth: CGFloat) -> CGFloat {
        let totalDuration = snapshot.endDate.timeIntervalSince(snapshot.startDate)
        guard totalDuration > 0 else { return totalWidth }
        let width = CGFloat(segment.endDate.timeIntervalSince(segment.startDate) / totalDuration) * totalWidth
        return max(width, 2)
    }

    private func color(for status: LayerStatus) -> Color {
        switch status {
        case .healthy:
            MenuPalette.good.opacity(0.76)
        case .degraded:
            MenuPalette.degraded.opacity(0.88)
        case .failed:
            MenuPalette.bad.opacity(0.92)
        case .pending:
            Color.secondary.opacity(0.16)
        case .unavailable:
            Color.secondary.opacity(0.28)
        }
    }
}
