import Foundation
import Combine
import AppKit

class SpotifyManager: ObservableObject {
    @Published var isPlaying: Bool = false
    @Published var trackName: String = ""
    @Published var artistName: String = ""
    @Published var progress: Double = 0.0
    @Published var durationSeconds: Double = 0.0
    @Published var isSpotifyRunning: Bool = false
    @Published var artworkUrl: URL? = nil
    @Published var volume: Double = 0.5 // 0.0 to 1.0

    private var timer: AnyCancellable?
    private var localTimer: AnyCancellable?
    private var isFetching = false
    private var isDraggingVolume = false
    private var volumeDebounceTimer: Timer?
    
    init() {
        startPolling()
    }
    
    func startPolling() {
        // Heavy AppleScript polling (reduced to every 1.0s)
        timer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.fetchSpotifyDataAsync()
            }
            
        // Buttery smooth local interpolation (runs every 0.05s)
        localTimer = Timer.publish(every: 0.05, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, self.isPlaying, self.durationSeconds > 0 else { return }
                // Smoothly increment progress locally between polls
                let increment = 0.05 / self.durationSeconds
                self.progress = min(1.0, self.progress + increment)
            }
    }
    
    private func fetchSpotifyDataAsync() {
        guard !isFetching else { return }
        isFetching = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            autoreleasepool {
                self?.fetchSpotifyData()
            }
            self?.isFetching = false
        }
    }
    
    private func fetchSpotifyData() {
        let bundleId = "com.spotify.client"
        let runningApps = NSWorkspace.shared.runningApplications
        let isRunning = runningApps.contains { $0.bundleIdentifier == bundleId }
        
        DispatchQueue.main.async {
            self.isSpotifyRunning = isRunning
            if !isRunning {
                self.isPlaying = false
            }
        }
        
        guard isRunning else {
            return
        }
        
        let scriptSource = """
        tell application id "com.spotify.client"
            with timeout of 2 seconds
                set pState to player state as string
                if pState is "playing" or pState is "paused" then
                    set tName to name of current track as string
                    set tArtist to artist of current track as string
                    set tDuration to duration of current track as string
                    set pPos to player position as string
                    try
                        set aUrl to artwork url of current track as string
                    on error
                        set aUrl to ""
                    end try
                    set sVol to sound volume as string
                    return pState & "|||" & tName & "|||" & tArtist & "|||" & tDuration & "|||" & pPos & "|||" & aUrl & "|||" & sVol
                else
                    return pState
                end if
            end timeout
        end tell
        """
        
        var error: NSDictionary?
        guard let script = NSAppleScript(source: scriptSource) else { return }
        let result = script.executeAndReturnError(&error)
        
        guard error == nil, let output = result.stringValue else {
            if let err = error, let errNum = err[NSAppleScript.errorNumber] as? Int {
                if errNum == -1743 {
                    DispatchQueue.main.async {
                        self.trackName = "Spotify Access Denied"
                        self.artistName = "Check System Settings > Privacy > Automation"
                    }
                }
            }
            return
        }
        
        let parts = output.components(separatedBy: "|||")
        let stateString = parts[0]
        
        DispatchQueue.main.async {
            self.isPlaying = (stateString == "playing")
            
            if (stateString == "playing" || stateString == "paused") && parts.count == 7 {
                self.trackName = parts[1]
                self.artistName = parts[2]
                
                let durationMs = Double(parts[3]) ?? 0.0
                let positionSeconds = Double(parts[4]) ?? 0.0
                
                self.durationSeconds = durationMs / 1000.0
                
                if self.durationSeconds > 0 {
                    self.progress = positionSeconds / self.durationSeconds
                } else {
                    self.progress = 0
                }
                
                let urlString = parts[5]
                if !urlString.isEmpty, let url = URL(string: urlString) {
                    self.artworkUrl = url
                } else {
                    self.artworkUrl = nil
                }
                
                if !self.isDraggingVolume {
                    let vol = Double(parts[6]) ?? 50.0
                    self.volume = vol / 100.0
                }
            }
        }
    }
    
    func playPause() {
        runAppleScriptAsync("tell application id \"com.spotify.client\" to playpause")
    }
    
    func nextTrack() {
        runAppleScriptAsync("tell application id \"com.spotify.client\" to next track")
    }
    
    func previousTrack() {
        runAppleScriptAsync("tell application id \"com.spotify.client\" to previous track")
    }
    
    func seek(to percentage: CGFloat) {
        if durationSeconds > 0 {
            let newPosition = Double(percentage) * durationSeconds
            self.progress = Double(percentage)
            runAppleScriptAsync("tell application id \"com.spotify.client\" to set player position to \(newPosition)")
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
            // Debounce the AppleScript call to avoid freezing the system
            volumeDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { [weak self] _ in
                self?.commitVolume()
            }
        }
    }
    
    private func commitVolume() {
        let vol = max(0, min(100, Int(self.volume * 100)))
        runAppleScriptAsync("tell application id \"com.spotify.client\" to set sound volume to \(vol)")
    }
    
    private func runAppleScriptAsync(_ source: String) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            if let script = NSAppleScript(source: source) {
                var error: NSDictionary?
                script.executeAndReturnError(&error)
                self?.fetchSpotifyData()
            }
        }
    }
}
