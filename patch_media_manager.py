import re

with open('src/SystemMediaManager.swift', 'r') as f:
    content = f.read()

# Replace timer definition
content = content.replace("private var timer: AnyCancellable?", "")

# Replace setupWorkspaceObservers and checkAndAdjustPolling and startPolling
pattern = r"private func setupWorkspaceObservers\(\) \{.*?(?=private func fetchMediaData\(\) \{)"
replacement = """private func setupWorkspaceObservers() {
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
    
    """
content = re.sub(pattern, replacement, content, flags=re.DOTALL)

with open('src/SystemMediaManager.swift', 'w') as f:
    f.write(content)

