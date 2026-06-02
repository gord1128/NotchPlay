import AppKit
import Foundation

class AutoUpdater {
    
    // Replace with the actual repository
    static let repoURL = "gord1128/NotchPlay"
    static let releaseAPI = "https://api.github.com/repos/\(repoURL)/releases/latest"
    static let releasesPage = "https://github.com/\(repoURL)/releases/latest"
    
    static func checkForUpdates() {
        guard let url = URL(string: releaseAPI) else { return }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("AutoUpdater: Failed to fetch release data.")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let tagName = json["tag_name"] as? String {
                    
                    let latestVersion = tagName.replacingOccurrences(of: "v", with: "")
                    
                    if let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                        
                        if isNewerVersion(latest: latestVersion, current: currentVersion) {
                            DispatchQueue.main.async {
                                showUpdateAlert(latestVersion: latestVersion, currentVersion: currentVersion)
                            }
                        } else {
                            print("AutoUpdater: App is up to date (v\(currentVersion)).")
                        }
                    }
                }
            } catch {
                print("AutoUpdater: Failed to parse JSON.")
            }
        }
        
        task.resume()
    }
    
    private static func isNewerVersion(latest: String, current: String) -> Bool {
        return latest.compare(current, options: .numeric) == .orderedDescending
    }
    
    private static func showUpdateAlert(latestVersion: String, currentVersion: String) {
        let alert = NSAlert()
        alert.messageText = "새로운 버전이 출시되었습니다!"
        alert.informativeText = "NotchPlay 최신 버전(v\(latestVersion))을 다운로드할 수 있습니다. 현재 버전은 v\(currentVersion) 입니다. 지금 업데이트 하시겠습니까?"
        alert.alertStyle = .informational
        
        alert.addButton(withTitle: "업데이트")
        alert.addButton(withTitle: "나중에")
        
        // Ensure alert pops up in front of other windows
        NSApp.activate(ignoringOtherApps: true)
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            if let url = URL(string: releasesPage) {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
