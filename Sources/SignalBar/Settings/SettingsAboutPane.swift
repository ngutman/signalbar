import AppKit
import SwiftUI

@MainActor
struct SettingsAboutPane: View {
    private var versionString: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String

        switch (version, build) {
        case let (.some(version), .some(build)):
            return "Version \(version) (\(build))"
        case let (.some(version), .none):
            return "Version \(version)"
        default:
            return "Development build"
        }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .center, spacing: 16) {
                Image(nsImage: NSApplication.shared.applicationIconImage)
                    .resizable()
                    .frame(width: 92, height: 92)
                    .cornerRadius(18)

                VStack(spacing: 4) {
                    Text("SignalBar")
                        .font(.title3.bold())
                    Text(versionString)
                        .foregroundStyle(.secondary)
                    Text("Diagnosis-first network health for Link, DNS, Internet, and Quality.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .center, spacing: 10) {
                    SettingsLinkRow(
                        icon: "chevron.left.slash.chevron.right",
                        title: "GitHub",
                        url: "https://github.com/ngutman/signalbar")
                    SettingsLinkRow(
                        icon: "book",
                        title: "Getting started",
                        url: "https://github.com/ngutman/signalbar/blob/main/docs/getting-started.md")
                    SettingsLinkRow(
                        icon: "lock.shield",
                        title: "Privacy",
                        url: "https://github.com/ngutman/signalbar/blob/main/docs/privacy.md")
                    SettingsLinkRow(
                        icon: "shippingbox",
                        title: "Releases",
                        url: "https://github.com/ngutman/signalbar/releases")
                }
                .frame(maxWidth: .infinity)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
    }
}
