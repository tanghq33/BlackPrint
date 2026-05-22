import SwiftUI
import AppKit

struct AboutView: View {
    private let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

    var body: some View {
        VStack(spacing: 12) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)
            Text("BlackPrint")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Version \(version)")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(width: 240)
    }
}
