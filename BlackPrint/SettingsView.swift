import SwiftUI
import AppKit

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings
    @State private var printers: [String] = NSPrinter.printerNames

    var body: some View {
        @Bindable var settings = settings
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 16) {
                Image(nsImage: NSApplication.shared.applicationIconImage)
                    .resizable()
                    .frame(width: 128, height: 128)

                VStack(alignment: .leading, spacing: 6) {
                    Text("BlackPrint")
                        .font(.headline)
                    Label("Left-click the menu bar icon to show the drop zone",
                          systemImage: "cursorarrow.click")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Label("Drag PDFs onto the drop zone to print in B&W",
                          systemImage: "doc.badge.arrow.up")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 2)

            Form {
                Section {
                    Picker("Printer", selection: $settings.selectedPrinterName) {
                        Text("None").tag(String?.none)
                        ForEach(printers, id: \.self) { name in
                            Text(name).tag(Optional(name))
                        }
                    }
                }

                Section {
                    LabeledContent("Paper & Orientation") {
                        HStack(spacing: 8) {
                            Text(settings.pageSetupSummary)
                                .foregroundStyle(.secondary)
                            Button("Page Setup…") {
                                let info = settings.buildPrintInfo()
                                let layout = NSPageLayout()
                                if layout.runModal(with: info) == NSApplication.ModalResponse.OK.rawValue {
                                    settings.savePrintInfo(info)
                                }
                            }
                        }
                    }
                }

                Section {
                    Toggle("Launch at Startup", isOn: $settings.launchAtStartup)
                    Toggle("Debug Mode", isOn: $settings.isDebugMode)
                }

                Section("Panel") {
                    Toggle("Auto-close after printing", isOn: $settings.autoCloseEnabled)
                    Stepper(
                        "Close after \(settings.autoCloseDelay)s",
                        value: $settings.autoCloseDelay,
                        in: 1...30
                    )
                    .disabled(!settings.autoCloseEnabled)
                }
            }
            .formStyle(.grouped)
        }
        .onAppear { printers = NSPrinter.printerNames }
    }
}
