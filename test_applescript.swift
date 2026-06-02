import Foundation

let scriptSource = """
tell application id "com.spotify.client"
    set pState to player state as string
    return pState
end tell
"""

if let script = NSAppleScript(source: scriptSource) {
    var error: NSDictionary?
    let result = script.executeAndReturnError(&error)
    print("Result: \(result.stringValue ?? "nil")")
    if let error = error {
        print("Error: \(error)")
    }
}
