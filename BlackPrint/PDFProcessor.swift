import Foundation
import PDFKit
import CoreGraphics
import CoreImage
import CoreImage.CIFilterBuiltins
import AppKit

enum PDFProcessorError: LocalizedError {
    case invalidDocument
    case noPages
    case renderFailed(page: Int)

    var errorDescription: String? {
        switch self {
        case .invalidDocument: return "Could not load the PDF document."
        case .noPages: return "The PDF document has no pages."
        case .renderFailed(let p): return "Failed to render page \(p + 1)."
        }
    }
}

actor PDFProcessor {
    func convertToBlackAndWhite(url: URL) async throws -> Data {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }

        guard let sourceDoc = PDFDocument(url: url) else {
            throw PDFProcessorError.invalidDocument
        }
        guard sourceDoc.pageCount > 0 else {
            throw PDFProcessorError.noPages
        }

        let outputDoc = PDFDocument()
        for i in 0..<sourceDoc.pageCount {
            guard let page = sourceDoc.page(at: i) else {
                throw PDFProcessorError.renderFailed(page: i)
            }
            let grayImage = try renderToGrayscale(page: page, index: i)
            guard let grayPage = PDFPage(image: grayImage) else {
                throw PDFProcessorError.renderFailed(page: i)
            }
            outputDoc.insert(grayPage, at: i)
        }

        guard let data = outputDoc.dataRepresentation() else {
            throw PDFProcessorError.renderFailed(page: 0)
        }
        return data
    }

    private func renderToGrayscale(page: PDFPage, index: Int) throws -> NSImage {
        let bounds = page.bounds(for: .mediaBox)
        let scale: CGFloat = 4.0
        let w = Int(bounds.width * scale)
        let h = Int(bounds.height * scale)

        guard let ctx = CGContext(
            data: nil, width: w, height: h,
            bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw PDFProcessorError.renderFailed(page: index)
        }
        ctx.setFillColor(red: 1, green: 1, blue: 1, alpha: 1)
        ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
        ctx.scaleBy(x: scale, y: scale)
        page.draw(with: .mediaBox, to: ctx)

        guard let cgImage = ctx.makeImage() else {
            throw PDFProcessorError.renderFailed(page: index)
        }

        let ciImage = CIImage(cgImage: cgImage)

        let desatFilter = CIFilter.colorControls()
        desatFilter.inputImage = ciImage
        desatFilter.saturation = 0

        guard let desatOutput = desatFilter.outputImage,
              let thresholdFilter = CIFilter(name: "CIColorThreshold") else {
            throw PDFProcessorError.renderFailed(page: index)
        }
        thresholdFilter.setValue(desatOutput, forKey: kCIInputImageKey)
        thresholdFilter.setValue(0.75, forKey: "inputThreshold")

        let ciContext = CIContext()
        guard let outputCI = thresholdFilter.outputImage,
              let bwCG = ciContext.createCGImage(outputCI, from: outputCI.extent) else {
            throw PDFProcessorError.renderFailed(page: index)
        }

        return NSImage(cgImage: bwCG, size: bounds.size)
    }
}
