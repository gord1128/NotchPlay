with open('src/SystemMediaManager.swift', 'r') as f:
    content = f.read()

controls = """
    // F-01: Playback Controls
    func playPause() {
        guard isMediaRunning else { return }
        let script = activePlayer == "Spotify" ? "tell application \\"Spotify\\" to playpause" : "tell application \\"Music\\" to playpause"
        _ = runAppleScript(script)
    }
    
    func nextTrack() {
        guard isMediaRunning else { return }
        let script = activePlayer == "Spotify" ? "tell application \\"Spotify\\" to next track" : "tell application \\"Music\\" to next track"
        _ = runAppleScript(script)
    }
    
    func previousTrack() {
        guard isMediaRunning else { return }
        let script = activePlayer == "Spotify" ? "tell application \\"Spotify\\" to previous track" : "tell application \\"Music\\" to previous track"
        _ = runAppleScript(script)
    }
}
"""

content = content.rsplit("}", 1)[0] + controls
with open('src/SystemMediaManager.swift', 'w') as f:
    f.write(content)
