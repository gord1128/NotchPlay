import Foundation

let script = """
tell application "System Events"
    return "Hello"
end tell
"""

let start = CFAbsoluteTimeGetCurrent()
for _ in 0..<10 {
    let task = Process()
    task.launchPath = "/usr/bin/osascript"
    task.arguments = ["-e", script]
    let pipe = Pipe()
    task.standardOutput = pipe
    task.launch()
    task.waitUntilExit()
}
print("Process overhead: \(CFAbsoluteTimeGetCurrent() - start) seconds")

let start2 = CFAbsoluteTimeGetCurrent()
for _ in 0..<10 {
    var error: NSDictionary?
    let appleScript = NSAppleScript(source: script)!
    appleScript.executeAndReturnError(&error)
}
print("NSAppleScript overhead: \(CFAbsoluteTimeGetCurrent() - start2) seconds")
