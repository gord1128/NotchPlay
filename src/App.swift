import AppKit
import SwiftUI
import ServiceManagement

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var windowController: NotchWindowController?
    let notchState = NotchState()
    var activity: NSObjectProtocol?
    var statusItem: NSStatusItem?
    
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        let delegate = AppDelegate()
        app.delegate = delegate
        withExtendedLifetime(delegate) {
            app.run()
        }
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Request Accessibility permissions if not granted (needed for Notch click global monitor)
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        // Ensure AppleEvent permission prompts for Music and Spotify show up over everything
        NSApp.activate(ignoringOtherApps: true)
        // Remove forced AppleScript execution to prevent auto-launching Music/Spotify
        // Permissions will be requested naturally when the user actually opens the respective apps.
        
        // Prevent the app from being automatically terminated or napped by macOS when idle
        ProcessInfo.processInfo.disableAutomaticTermination("NotchPlay background polling")
        ProcessInfo.processInfo.disableSuddenTermination()
        
        // Keep the app active in the background for continuous Spotify API polling
        activity = ProcessInfo.processInfo.beginActivity(
            options: [.userInitiated, .latencyCritical, .background],
            reason: "Continuous Notch UI and API Polling"
        )
        
        let notchView = NotchView(notchState: notchState)
        windowController = NotchWindowController(rootView: notchView, state: notchState)
        windowController?.showWindow(nil)
        
        AutoUpdater.checkForUpdates()
        
        setupMenuBar()
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "music.note.house.fill", accessibilityDescription: "NotchPlay")
            button.image?.isTemplate = true
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "NotchPlay is Running", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit NotchPlay", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
}
