import Observation
import SignalBarCore
import SwiftUI

struct MenuOverviewCardView: View {
    @Bindable var store: HealthStore
    let width: CGFloat

    private var presentation: StatusPresentation {
        store.presentation
    }

    private var targetRows: [TargetRowViewState] {
        [presentation.watchedTargetRow].compactMap(\.self) + presentation.targetRows
    }

    private var badges: [MenuHeaderBadgeState] {
        var badges: [MenuHeaderBadgeState] = []
        if store.isPaused {
            badges.append(.init(label: "Paused", tone: .warning))
        } else if store.toolbarState.isDimmed {
            badges.append(.init(label: "Stale", tone: .warning))
        }
        if store.toolbarState.overlay == .watchedTargetBadge {
            badges.append(.init(label: "Watched", tone: .accent))
        }
        return badges
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            headerSection
            layerSection
            historySection
            if HistoryModeDisplayLogic.shouldShowTargetsCard(
                selectedMetric: store.historyMetric,
                targetCount: targetRows.count)
            {
                targetsSection
            }
        }
        .padding(10)
        .frame(width: width, alignment: .leading)
    }

    private var headerSection: some View {
        MenuCardSection {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(presentation.titleText)
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer(minLength: 8)
                    Text(updatedText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(presentation.summaryText)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(alignment: .center, spacing: 8) {
                    Text(presentation.contextText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer(minLength: 8)
                    ForEach(badges) { badge in
                        MenuHeaderBadgeView(state: badge)
                    }
                }
            }
        }
    }

    private var layerSection: some View {
        MenuCardSection {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(presentation.layerRows) { row in
                    MenuLayerRowView(row: row)
                }
            }
        }
    }

    private var historySection: some View {
        MenuCardSection {
            MenuHistorySectionView(store: store)
        }
    }

    private var targetsSection: some View {
        MenuCardSection {
            VStack(alignment: .leading, spacing: 8) {
                Text("Targets")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ForEach(targetRows) { row in
                    MenuTargetRowView(row: row)
                }
            }
        }
    }

    private var updatedText: String {
        let updatedAt = store.updatedAt
        let secondsSinceUpdate = store.currentDate.timeIntervalSince(updatedAt)
        if abs(secondsSinceUpdate) < 5 {
            return "Updated just now"
        }
        return "Updated \(MenuFormatters.relative.localizedString(for: updatedAt, relativeTo: store.currentDate))"
    }
}
