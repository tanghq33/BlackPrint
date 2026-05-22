import Foundation
import Observation
import AppKit
import ServiceManagement

@Observable
final class AppSettings {
    var selectedPrinterName: String? {
        didSet { UserDefaults.standard.set(selectedPrinterName, forKey: "selectedPrinterName") }
    }

    var isDebugMode: Bool = false {
        didSet { UserDefaults.standard.set(isDebugMode, forKey: "isDebugMode") }
    }

    var autoCloseEnabled: Bool = true {
        didSet { UserDefaults.standard.set(autoCloseEnabled, forKey: "autoCloseEnabled") }
    }

    var autoCloseDelay: Int = 3 {
        didSet { UserDefaults.standard.set(autoCloseDelay, forKey: "autoCloseDelay") }
    }

    private var printInfoData: Data? {
        didSet { UserDefaults.standard.set(printInfoData, forKey: "printInfoData") }
    }

    init() {
        selectedPrinterName = UserDefaults.standard.string(forKey: "selectedPrinterName")
        isDebugMode = UserDefaults.standard.bool(forKey: "isDebugMode")
        autoCloseEnabled = UserDefaults.standard.object(forKey: "autoCloseEnabled") as? Bool ?? true
        autoCloseDelay = UserDefaults.standard.object(forKey: "autoCloseDelay") as? Int ?? 3
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

    var launchAtStartup: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            if newValue {
                try? SMAppService.mainApp.register()
            } else {
                try? SMAppService.mainApp.unregister()
            }
        }
    }

    var pageSetupSummary: String {
        let info = buildPrintInfo()
        let paper = info.paperName?.rawValue ?? "Default"
        let orientation = info.orientation == .landscape ? "Landscape" : "Portrait"
        return "\(paper) · \(orientation)"
    }
}
