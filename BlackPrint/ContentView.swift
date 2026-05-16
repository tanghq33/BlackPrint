import SwiftUI

enum ProcessingState: Equatable {
    case idle
    case processing(filename: String)
    case success(filename: String)
    case failure(message: String)
}

struct ContentView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(DropState.self) private var dropState
    @State private var processingState: ProcessingState = .idle
    @State private var showSettings = false

    private let processor = PDFProcessor()
    private let printService = PrintService()

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                toolbar
                Divider()
                dropZone
                    .padding(16)
                statusRow
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            }
            .frame(maxWidth: .infinity)
            .offset(x: showSettings ? -320 : 0)
            .allowsHitTesting(!showSettings)

            SettingsView(isPresented: $showSettings)
                .frame(maxWidth: .infinity)
                .offset(x: showSettings ? 0 : 320)
                .allowsHitTesting(showSettings)
        }
        .frame(width: 320)
        .clipped()
        .glassEffect(in: RoundedRectangle(cornerRadius: 12))
        .animation(.easeInOut(duration: 0.22), value: showSettings)
        .environment(\.controlActiveState, .active)
        .onChange(of: dropState.pendingURLs) { _, urls in
            guard !urls.isEmpty, !showSettings else { return }
            let captured = urls
            dropState.pendingURLs = []
            Task {
                for url in captured { await process(url: url) }
            }
        }
    }

    private var toolbar: some View {
        HStack {
            Text("BlackPrint")
                .font(.headline)
            Spacer()
            Button {
                dropState.stayOpen.toggle()
            } label: {
                Image(systemName: dropState.stayOpen ? "pin.fill" : "pin")
                    .imageScale(.medium)
                    .foregroundStyle(dropState.stayOpen ? Color.accentColor : Color.secondary)
            }
            .buttonStyle(.borderless)
            .help(dropState.stayOpen ? "Panel pinned open" : "Pin panel open")
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .imageScale(.medium)
            }
            .buttonStyle(.borderless)
            .help("Settings")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var dropZone: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(
                    dropState.isTargeted ? Color.accentColor : Color.secondary.opacity(0.4),
                    style: dropState.isTargeted
                        ? StrokeStyle(lineWidth: 2.5)
                        : StrokeStyle(lineWidth: 2, dash: [6, 4])
                )
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(dropState.isTargeted
                              ? Color.accentColor.opacity(0.22)
                              : Color.secondary.opacity(0.05))
                )

            VStack(spacing: 10) {
                Image(systemName: dropState.isTargeted ? "arrow.down.doc.fill" : "doc.badge.arrow.up")
                    .font(.system(size: 36, weight: dropState.isTargeted ? .regular : .light))
                    .foregroundStyle(dropState.isTargeted ? Color.accentColor : Color.secondary)
                Text(dropState.isTargeted ? "Release to Print" : "Drop PDFs Here")
                    .font(.callout)
                    .fontWeight(dropState.isTargeted ? .medium : .regular)
                    .foregroundStyle(dropState.isTargeted ? Color.accentColor : Color.secondary)
                Text(dropState.isTargeted ? "Will convert to B&W" : "Converts to B&W and prints")
                    .font(.caption)
                    .foregroundStyle(dropState.isTargeted
                                     ? Color.accentColor.opacity(0.8)
                                     : Color.secondary.opacity(0.7))
            }
        }
        .frame(height: 140)
        .scaleEffect(dropState.isTargeted ? 1.04 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: dropState.isTargeted)
    }

    @ViewBuilder
    private var statusRow: some View {
        switch processingState {
        case .idle:
            Color.clear.frame(height: 24)

        case .processing(let filename):
            HStack(spacing: 8) {
                ProgressView().controlSize(.small)
                Text("Processing \(filename)…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer()
            }
            .frame(height: 24)

        case .success(let filename):
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("\(filename) sent to printer")
                    .font(.caption)
                    .lineLimit(1)
                Spacer()
            }
            .frame(height: 24)

        case .failure(let message):
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Spacer()
            }
            .frame(minHeight: 24)
        }
    }

    private func process(url: URL) async {
        let filename = url.lastPathComponent
        processingState = .processing(filename: filename)

        do {
            let bwData = try await processor.convertToBlackAndWhite(url: url)
            let successName: String
            if settings.isDebugMode {
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("blackprint_\(UUID().uuidString)")
                    .appendingPathExtension("pdf")
                try bwData.write(to: tempURL)
                NSWorkspace.shared.open(tempURL)
                successName = "\(filename) (preview)"
            } else {
                try printService.print(pdfData: bwData, settings: settings)
                successName = filename
            }
            processingState = .success(filename: successName)
            try? await Task.sleep(for: .seconds(3))
            if processingState == .success(filename: successName) {
                processingState = .idle
                if !dropState.stayOpen {
                    dropState.closePanel?()
                }
            }
        } catch {
            processingState = .failure(message: error.localizedDescription)
        }
    }
}
