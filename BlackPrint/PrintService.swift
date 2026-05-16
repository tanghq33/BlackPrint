import AppKit
import PDFKit

private final class PDFPrintingView: NSView {
    private let doc: PDFDocument
    private let pageRects: [NSRect]
    private var currentPageIndex = 0

    init(doc: PDFDocument) {
        self.doc = doc
        self.pageRects = (0..<doc.pageCount).map { i in
            doc.page(at: i)?.bounds(for: .mediaBox) ?? NSRect(x: 0, y: 0, width: 612, height: 792)
        }
        let frame = pageRects.first ?? NSRect(x: 0, y: 0, width: 612, height: 792)
        super.init(frame: frame)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func knowsPageRange(_ range: NSRangePointer) -> Bool {
        range.pointee = NSRange(location: 1, length: doc.pageCount)
        return true
    }

    override func rectForPage(_ page: Int) -> NSRect {
        let idx = page - 1
        guard idx >= 0 && idx < pageRects.count else {
            return pageRects.first ?? NSRect(x: 0, y: 0, width: 612, height: 792)
        }
        currentPageIndex = idx
        return pageRects[idx]
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let page = doc.page(at: currentPageIndex),
              let ctx = NSGraphicsContext.current?.cgContext else { return }
        page.draw(with: .mediaBox, to: ctx)
    }
}

enum PrintServiceError: LocalizedError {
    case noPrinterSelected
    case printerNotFound(String)
    case printOperationFailed

    var errorDescription: String? {
        switch self {
        case .noPrinterSelected:
            return "No printer selected. Please choose a printer in Settings (⌘,)."
        case .printerNotFound(let name):
            return "Printer \"\(name)\" is not available."
        case .printOperationFailed:
            return "Could not prepare the document for printing."
        }
    }
}

final class PrintService {
    func print(pdfData: Data, settings: AppSettings) throws {
        guard let name = settings.selectedPrinterName, !name.isEmpty else {
            throw PrintServiceError.noPrinterSelected
        }
        guard let printer = NSPrinter(name: name) else {
            throw PrintServiceError.printerNotFound(name)
        }
        guard let doc = PDFDocument(data: pdfData) else {
            throw PrintServiceError.printOperationFailed
        }

        let printInfo = settings.buildPrintInfo()
        printInfo.printer = printer

        let printView = PDFPrintingView(doc: doc)
        let op = NSPrintOperation(view: printView, printInfo: printInfo)
        op.showsPrintPanel = false
        op.showsProgressPanel = false
        op.run()
    }
}
