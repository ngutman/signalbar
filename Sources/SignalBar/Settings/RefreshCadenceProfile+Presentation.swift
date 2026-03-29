import SignalBarCore

extension RefreshCadenceProfile {
    var displayName: String {
        switch self {
        case .powerSaver:
            "Power Saver"
        case .balanced:
            "Balanced"
        case .responsive:
            "Responsive"
        case .custom:
            "Custom"
        }
    }

    func detailText(customIntervalSeconds: Int) -> String {
        switch self {
        case .powerSaver:
            "Probe less often to reduce background activity and battery impact."
        case .balanced:
            "Recommended. Keeps diagnostics timely without making SignalBar too chatty."
        case .responsive:
            "Probe more often for faster issue detection and recovery visibility."
        case .custom:
            "Run each default control target every \(customIntervalSeconds) seconds and stagger probes across that interval."
        }
    }
}
