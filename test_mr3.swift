import Foundation
import AppKit

let bundleURL = NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework")
guard let bundle = CFBundleCreate(kCFAllocatorDefault, bundleURL) else { exit(1) }

typealias MRMediaRemoteGetNowPlayingApplicationIsPlayingFunction = @convention(c) (DispatchQueue, @escaping (Bool) -> Void) -> Void
guard let pointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteGetNowPlayingApplicationIsPlaying" as CFString) else { exit(1) }

let MRMediaRemoteGetNowPlayingApplicationIsPlaying = unsafeBitCast(pointer, to: MRMediaRemoteGetNowPlayingApplicationIsPlayingFunction.self)

print("Fetching isPlaying...")
MRMediaRemoteGetNowPlayingApplicationIsPlaying(DispatchQueue.main) { playing in
    print("Is Playing: \(playing)")
    exit(0)
}

RunLoop.main.run(until: Date(timeIntervalSinceNow: 2.0))
print("Timeout isPlaying")
