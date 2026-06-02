import Foundation
import Combine
import AppKit

class SystemAudioManager: ObservableObject {
    @Published var volume: Double = 0.5
    private var timer: AnyCancellable?
    private var isFetching = false
    private var isDraggingVolume = false
    private var volumeDebounceTimer: Timer?
    
    private var workspaceCancellable: AnyCancellable?
    
    init() {
        startPolling()
        setupWorkspaceObservers()
    }
    
    private func setupWorkspaceObservers() {
        workspaceCancellable = NSWorkspace.shared.notificationCenter
            .publisher(for: NSWorkspace.didWakeNotification)
            .sink { [weak self] _ in
                self?.startPolling()
            }
    }
    
    func startPolling() {
        timer?.cancel()
        timer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.fetchSystemVolumeAsync()
            }
    }
    
    private func fetchSystemVolumeAsync() {
        guard !isFetching else { return }
        isFetching = true
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            autoreleasepool {
                let scriptSource = "output volume of (get volume settings)"
                if let script = NSAppleScript(source: scriptSource) {
                    var error: NSDictionary?
                    let result = script.executeAndReturnError(&error)
                    if error == nil, let volString = result.stringValue, let vol = Double(volString) {
                        DispatchQueue.main.async {
                            if self?.isDraggingVolume == false {
                                self?.volume = vol / 100.0
                            }
                        }
                    }
                }
            }
            self?.isFetching = false
        }
    }
    
    func setVolume(to value: Double, isFinished: Bool = false) {
        self.volume = value
        
        volumeDebounceTimer?.invalidate()
        
        if isFinished {
            self.isDraggingVolume = false
            commitVolume()
        } else {
            self.isDraggingVolume = true
            volumeDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { [weak self] _ in
                self?.commitVolume()
            }
        }
    }
    
    private func commitVolume() {
        let vol = max(0, min(100, Int(self.volume * 100)))
        DispatchQueue.global(qos: .userInitiated).async {
            autoreleasepool {
                let scriptSource = "set volume output volume \(vol)"
                if let script = NSAppleScript(source: scriptSource) {
                    var error: NSDictionary?
                    script.executeAndReturnError(&error)
                }
            }
        }
    }
}
