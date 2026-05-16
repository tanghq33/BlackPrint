import Foundation
import Observation
import AppKit

@Observable
final class AppSettings {
    var selectedPrinterName: String? {
        didSet { UserDefaults.standard.set(selectedPrinterName, forKey: "selectedPrinterName") }
    }

    var isDebugMode: Bool = false {
        didSet { UserDefaults.standard.set(isDebugMode, forKey: "isDebugMode") }
    }

    private var printInfoData: Data? {
        didSet { UserDefaults.standard.set(printInfoData, forKey: "printInfoData") }
    }

    init() {
        selectedPrinterName = UserDefaults.standard.string(forKey: "selectedPrinterName")
        isDebugMode = UserDefaults.standard.bool(forKey: "isDebugMode")
        printInfoData = UserDefaults.standard.data(forKey: "printInfoData")
    }

    func buildPrintInfo() -> NSPrintInfo {
        if let data = printInfoData,
           let info = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSPrintInfo.self, from: data) {
            return info
        }
        return NSPrintInfo.shared.copy() as! NSPrintInfo
    }

    func savePrintInfo(_ info: NSPrintInfo) {
        printInfoData = try? NSKeyedArchiver.archivedData(withRootObject: info, requiringSecureCoding: false)
    }

    var pageSetupSummary: String {
        let info = buildPrintInfo()
        let paper = info.paperName?.rawValue ?? "Default"
        let orientation = info.orientation == .landscape ? "Landscape" : "Portrait"
        return "\(paper) · \(orientation)"
    }
}
