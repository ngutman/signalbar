import AppKit
import Foundation
import SignalBarCore
import SwiftUI

@MainActor
enum MenuFormatters {
    static let historyTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .none
        return formatter
    }()

    static let axisTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()

    static let relative: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter
    }()
}

enum MenuPalette {
    static let good = Color(nsColor: .systemGreen)
    static let okay = Color(nsColor: .systemYellow)
    static let degraded = Color(nsColor: .systemOrange)
    static let bad = Color(nsColor: .systemRed)
    static let unavailable = Color.secondary
    static let cardBackground = Color(nsColor: .controlBackgroundColor).opacity(0.55)
    static let sectionBorder = Color.primary.opacity(0.08)
    static let plotBackground = Color.white.opacity(0.035)
    static let plotBorder = Color.white.opacity(0.08)
    static let grid = Color.white.opacity(0.08)
}

func formattedMetricValue(_ value: Double, metric: HistoryMetric) -> String {
    switch metric {
    case .ping, .jitter:
        "\(Int(value.rounded())) ms"
    case .reliability:
        "\(Int(value.rounded()))%"
    case .overview:
        ""
    }
}

func metricColor(for band: MetricQualityBand) -> Color {
    switch band {
    case .good:
        MenuPalette.good
    case .okay:
        MenuPalette.okay
    case .degraded:
        MenuPalette.degraded
    case .bad:
        MenuPalette.bad
    case .unavailable:
        MenuPalette.unavailable
    }
}

func qualityBand(for metric: HistoryMetric, value: Double) -> MetricQualityBand {
    HistoryMetricRules.qualityBand(for: metric, value: value)
}

func metricUpperBound(metric: HistoryMetric, maxValue: Double) -> Double {
    HistoryMetricRules.upperBound(for: metric, maxValue: maxValue)
}

func breakdownSeriesColor(index: Int) -> Color {
    let palette: [Color] = [
        .blue,
        .mint,
        .purple,
        .pink,
        .cyan,
        .indigo
    ]
    return palette[index % palette.count]
}
