import Foundation

typealias MRInfoFunction = @convention(c) (DispatchQueue, @escaping ([String: Any]?) -> Void) -> Void

let bundleURL = NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework")
guard let bundle = CFBundleCreate(kCFAllocatorDefault, bundleURL),
      let pointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteGetNowPlayingInfo" as CFString) else {
    exit(1)
}

let MRMediaRemoteGetNowPlayingInfo = unsafeBitCast(pointer, to: MRInfoFunction.self)

MRMediaRemoteGetNowPlayingInfo(DispatchQueue.main) { info in
    print("info is nil: \(info == nil)")
    exit(0)
}
RunLoop.main.run(until: Date(timeIntervalSinceNow: 1.0))
