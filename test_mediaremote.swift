import Foundation
import AppKit

let bundle = CFBundleCreate(kCFAllocatorDefault, NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework"))
if let bundle = bundle {
    let pointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteGetNowPlayingInfo" as CFString)
    print("Found pointer: \(String(describing: pointer))")
} else {
    print("Could not load MediaRemote")
}
