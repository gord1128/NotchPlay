import Foundation

struct LyricLine {
    let time: Double
    let text: String
}

class LyricsManager {
    var onLyricChange: ((String) -> Void)?
    private var allLyrics: [LyricLine] = []
    private var currentTrackName: String = ""
    private var currentArtistName: String = ""
    
    private var cache: [String: [LyricLine]] = [:]
    private var fetchWorkItem: DispatchWorkItem?
    
    func fetchLyrics(trackName: String, artistName: String) {
        guard trackName != currentTrackName || artistName != currentArtistName else { return }
        
        currentTrackName = trackName
        currentArtistName = artistName
        allLyrics = []
        lastLyric = nil
        
        DispatchQueue.main.async {
            self.onLyricChange?("")
        }
        
        guard !trackName.isEmpty, !artistName.isEmpty, trackName != "No Track" else { return }
        
        let cacheKey = "\(trackName) - \(artistName)"
        if let cached = cache[cacheKey] {
            self.allLyrics = cached
            return
        }
        
        fetchWorkItem?.cancel()
        
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            
            var components = URLComponents(string: "https://lrclib.net/api/get")
            components?.queryItems = [
                URLQueryItem(name: "track_name", value: trackName),
                URLQueryItem(name: "artist_name", value: artistName)
            ]
            
            guard let url = components?.url else { return }
            
            var request = URLRequest(url: url)
            request.setValue("NotchPlay/2.0 (macOS Media Controller)", forHTTPHeaderField: "User-Agent")
            
            URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                guard let self = self, let data = data else { return }
                
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let syncedLyrics = json["syncedLyrics"] as? String {
                    let parsed = self.parseLRC(syncedLyrics)
                    DispatchQueue.main.async {
                        self.cache[cacheKey] = parsed
                        if self.currentTrackName == trackName && self.currentArtistName == artistName {
                            self.allLyrics = parsed
                        }
                    }
                }
            }.resume()
        }
        
        fetchWorkItem = workItem
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.8, execute: workItem)
    }
    
    func updateProgress(_ currentTimeSeconds: Double) {
        guard !allLyrics.isEmpty else { return }
        
        // Find the closest lyric line
        // We find the last line that has a time <= currentTimeSeconds
        var foundLine: String = ""
        for line in allLyrics {
            if line.time <= currentTimeSeconds {
                foundLine = line.text
            } else {
                break
            }
        }
        
        if lastLyric != foundLine {
            lastLyric = foundLine
            self.onLyricChange?(foundLine)
        }
    }
    private var lastLyric: String?
    
    private func parseLRC(_ lrc: String) -> [LyricLine] {
        var lines: [LyricLine] = []
        let regex = try! NSRegularExpression(pattern: "\\[(\\d{2}):(\\d{2}\\.\\d+)\\](.*)")
        
        let stringLines = lrc.components(separatedBy: .newlines)
        for line in stringLines {
            let nsRange = NSRange(line.startIndex..<line.endIndex, in: line)
            if let match = regex.firstMatch(in: line, range: nsRange) {
                let minStr = (line as NSString).substring(with: match.range(at: 1))
                let secStr = (line as NSString).substring(with: match.range(at: 2))
                let text = (line as NSString).substring(with: match.range(at: 3)).trimmingCharacters(in: .whitespaces)
                
                if let min = Double(minStr), let sec = Double(secStr) {
                    let time = (min * 60) + sec
                    if !text.isEmpty {
                        lines.append(LyricLine(time: time, text: text))
                    }
                }
            }
        }
        return lines
    }
}
