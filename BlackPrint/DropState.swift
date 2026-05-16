import Foundation
import Observation

@Observable
final class DropState {
    var isTargeted = false
    var pendingURLs: [URL] = []
    var stayOpen = false
    var closePanel: (() -> Void)?
}
