import Foundation
import ScriptingBridge

@objc public protocol SpotifyApplication {
    @objc optional var currentTrack: SpotifyTrack { get }
    @objc optional var playerState: SpotifyEPlS { get }
    @objc optional var playerPosition: Double { get }
}

@objc public protocol SpotifyTrack {
    @objc optional var name: String { get }
    @objc optional var artist: String { get }
    @objc optional var duration: Int { get }
}

@objc public enum SpotifyEPlS: Int {
    case stopped = 0x70537470 // 'pStp'
    case playing = 0x70506c61 // 'pPla'
    case paused = 0x70506175 // 'pPau'
}

extension SBApplication: SpotifyApplication {}
