import SwiftUI
import AppKit

struct SettingsView: View {
    @Binding var isPresented: Bool
    @Environment(AppSettings.self) private var settings
    @State private var printers: [String] = NSPrinter.printerNames

    var body: some View {
        @Bindable var settings = settings
        VStack(spacing: 0) {
            // Nav header — mirrors main toolbar style
            HStack {
                Button {
                    isPresented = false
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "chevron.left")
                            .fontWeight(.semibold)
                            .imageScale(.small)
                        Text("Back")
                    }
                    .foregroundStyle(Color.accentColor)
                }
                .buttonStyle(.borderless)

                Spacer()

                Text("Settings")
                    .font(.headline)

                Spacer()

                // Balances the back button so title is centered
                Color.clear.frame(width: 50, height: 1)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()

            // Printer row
            HStack {
                Text("Printer")
                Spacer()
                Picker("", selection: $settings.selectedPrinterName) {
                    Text("None").tag(String?.none)
                    ForEach(printers, id: \.self) { name in
                        Text(name).tag(Optional(name))
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .fixedSize()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()
                .padding(.leading, 16)

            // Paper & Orientation row
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Paper & Orientation")
                    Text(settings.pageSetupSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Page Setup…") {
                    let info = settings.buildPrintInfo()
                    let layout = NSPageLayout()
                    if layout.runModal(with: info) == NSApplication.ModalResponse.OK.rawValue {
                        settings.savePrintInfo(info)
                    }
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()
                .padding(.leading, 16)

            // Debug toggle
            HStack {
                Text("Debug Mode")
                Spacer()
                PanelToggle(isOn: $settings.isDebugMode)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .onAppear {
            printers = NSPrinter.printerNames
        }
    }
}

// Custom toggle that always renders in colour — system toggles grey out in non-activating panels.
private struct PanelToggle: View {
    @Binding var isOn: Bool

    var body: some View {
        Capsule()
            .fill(isOn ? Color(red: 0, green: 0.478, blue: 1) : Color(nsColor: .tertiaryLabelColor))
            .frame(width: 44, height: 20)
            .overlay(
                Capsule()
                    .fill(.white)
                    .shadow(color: .black.opacity(0.2), radius: 1, y: 0.5)
                    .frame(width: 26, height: 16)
                    .offset(x: isOn ? 7 : -7)
                    .animation(.easeInOut(duration: 0.15), value: isOn)
            )
            .animation(.easeInOut(duration: 0.15), value: isOn)
            .onTapGesture { isOn.toggle() }
    }
}
