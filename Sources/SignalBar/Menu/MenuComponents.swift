import SignalBarCore
import SwiftUI

struct MenuHeaderBadgeState: Identifiable, Equatable {
    enum Tone: Equatable {
        case neutral
        case accent
        case warning
    }

    let label: String
    let tone: Tone

    var id: String {
        label
    }
}

struct MenuCardSection<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(MenuPalette.cardBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(MenuPalette.sectionBorder, lineWidth: 1))
    }
}

struct MenuHeaderBadgeView: View {
    let state: MenuHeaderBadgeState

    var body: some View {
        Text(state.label)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(foregroundColor)
            .background(
                Capsule(style: .continuous)
                    .fill(backgroundColor))
    }

    private var backgroundColor: Color {
        switch state.tone {
        case .neutral:
            Color.primary.opacity(0.08)
        case .accent:
            Color.accentColor.opacity(0.18)
        case .warning:
            Color.orange.opacity(0.18)
        }
    }

    private var foregroundColor: Color {
        switch state.tone {
        case .neutral:
            .secondary
        case .accent:
            .accentColor
        case .warning:
            .orange
        }
    }
}

struct MenuLayerRowView: View {
    let row: LayerRowViewState

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(row.layer.displayName)
                .font(.subheadline)
                .fontWeight(.medium)
            Spacer(minLength: 8)
            Text(row.status.displayName)
                .font(.caption)
                .foregroundStyle(statusColor)
            Text(row.metricText)
                .font(.subheadline)
                .fontWeight(.semibold)
                .monospacedDigit()
                .lineLimit(1)
        }
    }

    private var statusColor: Color {
        Self.color(for: row.status)
    }

    static func color(for status: LayerStatus) -> Color {
        switch status {
        case .healthy:
            .secondary
        case .degraded:
            MenuPalette.degraded
        case .failed:
            MenuPalette.bad
        case .pending, .unavailable:
            .secondary.opacity(0.7)
        }
    }
}

struct MenuTargetRowView: View {
    let row: TargetRowViewState

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 10) {
                Circle()
                    .fill(toneColor)
                    .frame(width: 7, height: 7)
                Text(row.labelText)
                    .font(.subheadline)
                    .lineLimit(1)
                Spacer(minLength: 8)
                Text(row.statusText)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                    .foregroundStyle(toneColor)
            }
            if let detailText = row.detailText {
                Text(detailText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 17)
            }
        }
    }

    private var toneColor: Color {
        switch row.tone {
        case .healthy:
            .secondary
        case .degraded:
            MenuPalette.degraded
        case .failed:
            MenuPalette.bad
        case .pending:
            .secondary.opacity(0.7)
        }
    }
}
