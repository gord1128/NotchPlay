import Combine
import AppKit
import SwiftUI

enum SupportedMediaApp: String {
    case music = "Music"
    case spotify = "Spotify"
}

class SystemMediaManager: ObservableObject {
    @Published var isMediaRunning: Bool = false
    @Published var isPlaying: Bool = false
    @Published var trackName: String = "No Track"
    @Published var artistName: String = "No Artist"
    @Published var progress: Double = 0.0
    @Published var durationSeconds: Double = 0.0
    @Published var artworkImage: NSImage? = nil
    @Published var appVolume: Double = 0.5
    @Published var currentLyric: String = ""
    @Published var currentRomaji: String = ""
    
    var lyricsManager = LyricsManager()
    
    var isDraggingAppVolume: Bool = false
    var isDraggingProgress: Bool = false
    
    
    private var localTimer: AnyCancellable?
    
    // Cache
    private var lastArtworkUrl: String? = nil
    var activePlayer: String = "None"
    
    private var workspaceCancellables = Set<AnyCancellable>()
    
    init() {
        setupWorkspaceObservers()
        checkAndAdjustPolling()
    }
    
    private func setupWorkspaceObservers() {
        let nc = NSWorkspace.shared.notificationCenter
        let dnc = DistributedNotificationCenter.default()
        
        nc.publisher(for: NSWorkspace.didLaunchApplicationNotification)
            .sink { [weak self] notification in
                if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                   let bundleId = app.bundleIdentifier,
                   bundleId == "com.apple.Music" || bundleId == "com.spotify.client" {
                    self?.checkAndAdjustPolling()
                }
            }
            .store(in: &workspaceCancellables)
            
        nc.publisher(for: NSWorkspace.didTerminateApplicationNotification)
            .sink { [weak self] notification in
                if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                   let bundleId = app.bundleIdentifier,
                   bundleId == "com.apple.Music" || bundleId == "com.spotify.client" {
                    self?.checkAndAdjustPolling()
                }
            }
            .store(in: &workspaceCancellables)
            
        nc.publisher(for: NSWorkspace.didWakeNotification)
            .sink { [weak self] _ in
                self?.checkAndAdjustPolling()
            }
            .store(in: &workspaceCancellables)
            
        // F-04: Distributed Notifications for Media Player state changes
        dnc.addObserver(forName: NSNotification.Name("com.spotify.client.PlaybackStateChanged"), object: nil, queue: .main) { [weak self] _ in
            self?.fetchMediaData()
        }
        
        dnc.addObserver(forName: NSNotification.Name("com.apple.Music.playerInfo"), object: nil, queue: .main) { [weak self] _ in
            self?.fetchMediaData()
        }
    }
    
    private func checkAndAdjustPolling() {
        let runningApps = NSWorkspace.shared.runningApplications
        let isMusicRunning = runningApps.contains { $0.bundleIdentifier == "com.apple.Music" }
        let isSpotifyRunning = runningApps.contains { $0.bundleIdentifier == "com.spotify.client" }
        
        if !isMusicRunning && !isSpotifyRunning {
            localTimer?.cancel()
            localTimer = nil
            
            DispatchQueue.main.async {
                self.isMediaRunning = false
                self.activePlayer = "None"
                self.trackName = "No media playing"
                self.artistName = ""
                self.artworkImage = nil
                self.currentLyric = ""
                self.currentRomaji = ""
                self.lyricsManager.fetchLyrics(trackName: "", artistName: "")
            }
        } else {
            if localTimer == nil {
                startPolling()
            }
            fetchMediaData() // Initial fetch
        }
    }
    
    private func startPolling() {
        lyricsManager.onLyricChange = { [weak self] newLyric in
            DispatchQueue.main.async {
                if self?.currentLyric != newLyric {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        self?.currentLyric = newLyric
                        if FuriganaHelper.containsJapanese(newLyric) {
                            self?.currentRomaji = FuriganaHelper.getRomaji(for: newLyric)
                        } else {
                            self?.currentRomaji = ""
                        }
                    }
                }
            }
        }
        
        localTimer?.cancel()
        localTimer = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if !self.isDraggingProgress && self.isPlaying && self.durationSeconds > 0 {
                    self.progress += 0.1 / self.durationSeconds
                    if self.progress > 1.0 { self.progress = 1.0 }
                    
                    self.lyricsManager.updateProgress(self.progress * self.durationSeconds)
                }
            }
    }
    
    private func fetchMediaData() {
        DispatchQueue.global(qos: .userInitiated).async {
            // Check Apple Music
            let musicCheck = """
            try
                with timeout of 1 second
                    if application "Music" is running then
                        tell application "Music"
                            if player state is playing then return "MusicPlaying"
                            if player state is paused then return "MusicPaused"
                        end tell
                    end if
                end timeout
            end try
            return "NoMusic"
            """
            
            // Check Spotify
            let spotifyCheck = """
            try
                with timeout of 1 second
                    if application "Spotify" is running then
                        tell application "Spotify"
                            if player state is playing then return "SpotifyPlaying"
                            if player state is paused then return "SpotifyPaused"
                        end tell
                    end if
                end timeout
            end try
            return "NoSpotify"
            """
            
            let musicStatus = self.runAppleScript(musicCheck)
            let spotifyStatus = self.runAppleScript(spotifyCheck)
            
            var targetApp = "None"
            var playing = false
            
            let isMusicPlaying = (musicStatus == "MusicPlaying")
            let isSpotifyPlaying = (spotifyStatus == "SpotifyPlaying")
            let isMusicPaused = (musicStatus == "MusicPaused")
            let isSpotifyPaused = (spotifyStatus == "SpotifyPaused")
            
            if isMusicPlaying && isSpotifyPlaying {
                // If both are playing, prefer the one that was NOT active before (so if you switch, it picks it up)
                if self.activePlayer == "Spotify" {
                    targetApp = "Music"
                } else {
                    targetApp = "Spotify"
                }
                playing = true
            } else if isMusicPlaying {
                targetApp = "Music"
                playing = true
            } else if isSpotifyPlaying {
                targetApp = "Spotify"
                playing = true
            } else if isMusicPaused && isSpotifyPaused {
                // If both are paused, stick to the active player to prevent ping-pong
                if self.activePlayer == "Music" {
                    targetApp = "Music"
                } else if self.activePlayer == "Spotify" {
                    targetApp = "Spotify"
                } else {
                    targetApp = "Music" // Default fallback
                }
                playing = false
            } else if isMusicPaused {
                targetApp = "Music"
                playing = false
            } else if isSpotifyPaused {
                targetApp = "Spotify"
                playing = false
            }
            
            if targetApp == "None" {
                DispatchQueue.main.async {
                    self.isMediaRunning = false
                    self.isPlaying = false
                    self.trackName = "No Media Playing"
                    self.artistName = ""
                    self.progress = 0
                    self.durationSeconds = 0
                    self.artworkImage = nil
                    self.activePlayer = "None"
                }
                return
            }
            
            self.activePlayer = targetApp
            
            let metadataScript = """
            try
                with timeout of 1 second
                    tell application "\(targetApp)"
                        set tName to name of current track
                        set tArtist to artist of current track
                        set tDuration to duration of current track
                        set tPos to player position
                        set tVol to sound volume
                        return tName & "|||" & tArtist & "|||" & tDuration & "|||" & tPos & "|||" & tVol
                    end tell
                end timeout
            end try
            return "TIMEOUT"
            """
            
            let metaString = self.runAppleScript(metadataScript)
            let parts = metaString.components(separatedBy: "|||")
            
            if parts.count >= 5 {
                let name = parts[0]
                let artist = parts[1]
                let duration = (Double(parts[2]) ?? 0.0) / (targetApp == "Spotify" ? 1000.0 : 1.0)
                let pos = Double(parts[3]) ?? 0.0
                let vol = (Double(parts[4]) ?? 50.0) / 100.0
                
                DispatchQueue.main.async {
                    self.isMediaRunning = true
                    self.isPlaying = playing
                    self.trackName = name
                    self.artistName = artist
                    
                    if !self.isDraggingAppVolume {
                        if abs(self.appVolume - vol) > 0.02 {
                            self.appVolume = vol
                        }
                    }
                    
                    if duration > 0 {
                        self.durationSeconds = duration
                        if !self.isDraggingProgress {
                            let newProgress = pos / duration
                            if abs(self.progress - newProgress) > 0.02 {
                                self.progress = newProgress
                            }
                        }
                        self.lyricsManager.updateProgress(self.progress * self.durationSeconds)
                    }
                    
                    self.lyricsManager.fetchLyrics(trackName: name, artistName: artist)
                }
            }
            
            // Artwork fetching
            if targetApp == "Spotify" {
                let artworkScript = """
                tell application "Spotify"
                    return artwork url of current track
                end tell
                """
                let artUrl = self.runAppleScript(artworkScript)
                if artUrl != self.lastArtworkUrl, let url = URL(string: artUrl) {
                    self.lastArtworkUrl = artUrl
                    URLSession.shared.dataTask(with: url) { data, _, _ in
                        if let data = data, let img = NSImage(data: data) {
                            DispatchQueue.main.async { self.artworkImage = img }
                        }
                    }.resume()
                }
            } else if targetApp == "Music" {
                // Music stores artwork as raw data in AppleScript
                // To avoid slow AppleScript raw data extraction, we just query Music.app's current track artwork directly.
                // For performance, we check if the track changed.
                let trackIdScript = """
                try
                    with timeout of 1 second
                        tell application "Music"
                            return id of current track as string
                        end tell
                    end timeout
                end try
                return "FAIL"
                """
                let trackId = self.runAppleScript(trackIdScript)
                if trackId != "FAIL" && trackId != self.lastArtworkUrl {
                    self.lastArtworkUrl = trackId
                    
                    let uniqueFilename = UUID().uuidString + ".png"
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(uniqueFilename)
                    let tempPath = tempURL.path
                    
                    let artFetch = """
                    tell application "Music"
                        try
                            set artData to raw data of artwork 1 of current track
                            set outFile to open for access (POSIX file "\(tempPath)") with write permission
                            set eof outFile to 0
                            write artData to outFile
                            close access outFile
                            return "OK"
                        on error
                            return "FAIL"
                        end try
                    end tell
                    """
                    let artStatus = self.runAppleScript(artFetch)
                    if artStatus == "OK", let img = NSImage(contentsOfFile: tempPath) {
                        DispatchQueue.main.async { self.artworkImage = img }
                        try? FileManager.default.removeItem(atPath: tempPath)
                    } else {
                        DispatchQueue.main.async { self.artworkImage = nil }
                    }
                }
            }
        }
    }
    
    func launchApp(app: SupportedMediaApp) {
        let script = "tell application \"\(app.rawValue)\" to activate"
        DispatchQueue.global(qos: .userInitiated).async {
            var error: NSDictionary?
            if let appleScript = NSAppleScript(source: script) {
                appleScript.executeAndReturnError(&error)
            }
        }
}
    
    private func runAppleScript(_ script: String) -> String {
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            let output = appleScript.executeAndReturnError(&error)
            if let stringValue = output.stringValue {
                return stringValue
            }
        }
        return ""
    }
    
    func playPause() {
        if activePlayer != "None" {
            let player = activePlayer
            DispatchQueue.global(qos: .userInitiated).async {
                _ = self.runAppleScript("tell application \"\(player)\" to playpause")
            }
        }
    }
    func nextTrack() {
        if activePlayer != "None" {
            let player = activePlayer
            DispatchQueue.global(qos: .userInitiated).async {
                _ = self.runAppleScript("tell application \"\(player)\" to next track")
            }
        }
    }
    func previousTrack() {
        if activePlayer != "None" {
            let player = activePlayer
            DispatchQueue.global(qos: .userInitiated).async {
                _ = self.runAppleScript("tell application \"\(player)\" to previous track")
            }
        }
    }
    func setAppVolume(to percent: Double, isFinished: Bool = false) {
        if activePlayer != "None" {
            appVolume = percent
            let volInt = Int(percent * 100)
            let player = activePlayer
            DispatchQueue.global(qos: .userInitiated).async {
                _ = self.runAppleScript("tell application \"\(player)\" to set sound volume to \(volInt)")
            }
        }
    }
    func seek(to percent: Double) {
        if activePlayer != "None" && durationSeconds > 0 {
            progress = percent
            let pos = percent * durationSeconds
            let player = activePlayer
            DispatchQueue.global(qos: .userInitiated).async {
                _ = self.runAppleScript("tell application \"\(player)\" to set player position to \(pos)")
            }
        }
    }
}
