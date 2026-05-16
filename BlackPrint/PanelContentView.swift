import AppKit
import SwiftUI
import UniformTypeIdentifiers

final class PanelContentView: NSView {
    private let dropState: DropState

    init(hostingView: NSView, dropState: DropState) {
        self.dropState = dropState
        super.init(frame: .zero)
        addSubview(hostingView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        registerForDraggedTypes([.fileURL])
    }

    required init?(coder: NSCoder) { fatalError() }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard !pdfURLs(from: sender).isEmpty else { return [] }
        dropState.isTargeted = true
        return .copy
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        pdfURLs(from: sender).isEmpty ? [] : .copy
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        dropState.isTargeted = false
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let urls = pdfURLs(from: sender)
        guard !urls.isEmpty else { return false }
        dropState.isTargeted = false
        dropState.pendingURLs = urls
        return true
    }

    override func concludeDragOperation(_ sender: NSDraggingInfo?) {
        dropState.isTargeted = false
    }

    private func pdfURLs(from sender: NSDraggingInfo) -> [URL] {
        (sender.draggingPasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [
                .urlReadingFileURLsOnly: true,
                .urlReadingContentsConformToTypes: [UTType.pdf.identifier]
            ]
        ) as? [URL]) ?? []
    }
}
