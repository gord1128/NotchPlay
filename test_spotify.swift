import AppKit

let bundleId = "com.spotify.client"
let runningApps = NSWorkspace.shared.runningApplications
let isRunning = runningApps.contains { $0.bundleIdentifier == bundleId }

print("Is running: \(isRunning)")
