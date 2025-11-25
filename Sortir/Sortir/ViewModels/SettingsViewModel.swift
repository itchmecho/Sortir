import SwiftUI

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var showClearAlert = false
    @Published var clearMessage = ""

    private let coreDataService = CoreDataService.shared

    func clearAllData() {
        coreDataService.clearAllData()
        clearMessage = "All data cleared successfully"
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.clearMessage = ""
        }
    }
}
