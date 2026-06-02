import Foundation
import AppKit

let bundleURL = NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework")
guard let bundle = CFBundleCreate(kCFAllocatorDefault, bundleURL) else {
    print("Failed to load bundle")
    exit(1)
}

typealias MRMediaRemoteGetNowPlayingInfoFunction = @convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void
guard let pointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteGetNowPlayingInfo" as CFString) else {
    print("Failed to get function pointer")
    exit(1)
}

let MRMediaRemoteGetNowPlayingInfo = unsafeBitCast(pointer, to: MRMediaRemoteGetNowPlayingInfoFunction.self)

let group = DispatchGroup()
group.enter()

print("Fetching info...")
MRMediaRemoteGetNowPlayingInfo(DispatchQueue.main) { info in
    print("Got info: \(info)")
    group.leave()
}

group.wait()
