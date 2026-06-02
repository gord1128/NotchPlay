import Foundation

let getVolScript = "output volume of (get volume settings)"
if let script = NSAppleScript(source: getVolScript) {
    var error: NSDictionary?
    let result = script.executeAndReturnError(&error)
    print("Volume: \(result.stringValue ?? "nil")")
}

let setVolScript = "set volume output volume 40"
if let script = NSAppleScript(source: setVolScript) {
    var error: NSDictionary?
    script.executeAndReturnError(&error)
    print("Set volume to 40")
}
