import AppKit
import SwiftUI
import Combine

// Shared state between NotchView and NotchWindowController
class NotchState: ObservableObject {
    @Published var showProgressBar = false {
        didSet {
            if showProgressBar {
                resetDismissTimer()
            } else {
                dismissTimer?.invalidate()
            }
        }
    }
    @Published var isHovering = false {
        didSet {
            if isHovering {
                dismissTimer?.invalidate()
            } else if showProgressBar {
                resetDismissTimer()
            }
        }
    }
    
    private var dismissTimer: Timer?
    
    func resetDismissTimer() {
        dismissTimer?.invalidate()
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 8.0, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self = self, !self.isHovering else { return }
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    self.showProgressBar = false
                }
            }
        }
    }
}

class NotchWindowController: NSWindowController {
    var notchState: NotchState
    var globalClickMonitor: Any?
    var localClickMonitor: Any?
    var globalKeyMonitor: Any?
    var localKeyMonitor: Any?
    private var cancellables = Set<AnyCancellable>()
    
    private var cachedHotkeyCode: UInt16 = 46
    private var cachedHotkeyModifiers: NSEvent.ModifierFlags = [.command, .shift]
    
    convenience init(rootView: NotchView, state: NotchState) {
        let hostingController = NSHostingController(rootView: rootView)
        hostingController.view.wantsLayer = true
        hostingController.view.layer?.backgroundColor = NSColor.clear.cgColor
        hostingController.view.layer?.isOpaque = false
        
        let window = NotchWindow(contentRect: .zero,
                                 styleMask: [.borderless, .nonactivatingPanel],
                                 backing: .buffered,
                                 defer: false)
        
        window.contentViewController = hostingController
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.level = .statusBar
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.ignoresMouseEvents = true
        
        // Register default hotkey: Cmd + Shift + M (46)
        UserDefaults.standard.register(defaults: [
            "hotkeyCode": 46,
            "hotkeyModifiers": Int(NSEvent.ModifierFlags.command.rawValue | NSEvent.ModifierFlags.shift.rawValue)
        ])
        
        self.init(window: window)
        self.notchState = state
        positionUnderNotch()
        setupClickMonitors()
        setupHotkeyMonitors()
        setupWorkspaceObservers()
        
        // Observe state changes to manage window mouse events when auto-dismiss triggers
        self.notchState.$showProgressBar
            .sink { [weak self] show in
                if !show {
                    self?.window?.ignoresMouseEvents = true
                } else {
                    self?.window?.ignoresMouseEvents = false
                }
            }
            .store(in: &cancellables)
    }
    
    // Required by the convenience init chain
    override init(window: NSWindow?) {
        self.notchState = NotchState()
        super.init(window: window)
    }
    
    required init?(coder: NSCoder) {
        self.notchState = NotchState()
        super.init(coder: coder)
    }
    
    func positionUnderNotch(for targetScreen: NSScreen? = nil) {
        let screenToUse = targetScreen ?? NSScreen.main ?? NSScreen.screens.first
        guard let screen = screenToUse, let window = self.window else { return }
        
        let windowWidth: CGFloat = 260
        let windowHeight: CGFloat = 500
        
        let xPos = round(screen.frame.midX - (windowWidth / 2))
        var yPos: CGFloat = 0
        
        // F-02: Dynamic Monitor Adaptation
        if screen.safeAreaInsets.top > 0 {
            // Has notch, anchor exactly below the notch
            yPos = round(screen.frame.maxY - windowHeight)
        } else {
            // No notch (e.g. external monitor or older mac), anchor slightly below the menu bar
            // Menubar is usually 24px tall, so we place it below
            yPos = round(screen.frame.maxY - windowHeight - 24)
        }
        
        window.setFrame(NSRect(x: xPos, y: yPos, width: windowWidth, height: windowHeight), display: true)
    }
    
    func screenForNotchClick(_ locationInScreen: NSPoint) -> NSScreen? {
        let notchWidth: CGFloat = 200
        
        for screen in NSScreen.screens {
            let screenFrame = screen.frame
            
            // If the screen has no hardware notch AND the menu bar is hidden (e.g. Full Screen mode),
            // we ignore clicks in this region to prevent interfering with full-screen apps (like browser tabs).
            if screen.safeAreaInsets.top == 0 && screen.visibleFrame.maxY == screenFrame.maxY {
                continue
            }
            
            // Use hardware notch height if available, otherwise standard menubar height (24px)
            let notchHeight: CGFloat = screen.safeAreaInsets.top > 0 ? screen.safeAreaInsets.top : 24
            
            let notchMinX = screenFrame.midX - (notchWidth / 2)
            let notchMaxX = screenFrame.midX + (notchWidth / 2)
            let notchMinY = screenFrame.maxY - notchHeight
            
            if locationInScreen.x >= notchMinX &&
               locationInScreen.x <= notchMaxX &&
               locationInScreen.y >= notchMinY &&
               locationInScreen.y <= screenFrame.maxY + 50 { // Buffer for safety
                return screen
            }
        }
        return nil
    }
    
    func setupWorkspaceObservers() {
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
            self?.resetMonitors()
        }
        
        NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [weak self] _ in
            self?.resetMonitors()
        }
    }
    
    func resetMonitors() {
        if let monitor = globalClickMonitor { NSEvent.removeMonitor(monitor) }
        if let monitor = localClickMonitor { NSEvent.removeMonitor(monitor) }
        if let monitor = globalKeyMonitor { NSEvent.removeMonitor(monitor) }
        if let monitor = localKeyMonitor { NSEvent.removeMonitor(monitor) }
        
        setupClickMonitors()
        setupHotkeyMonitors()
    }
    
    func setupClickMonitors() {
        // Global monitor: catches clicks sent to OTHER apps (including menu bar / desktop)
        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown]) { [weak self] event in
            self?.handleClick(screenLocation: event.locationInWindow)
        }
        
        // Local monitor: catches clicks sent to OUR app
        localClickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown]) { [weak self] event in
            if let self = self {
                // Convert to screen coordinates
                if let windowForEvent = event.window {
                    let locationInWindow = event.locationInWindow
                    let screenLocation = windowForEvent.convertPoint(toScreen: locationInWindow)
                    self.handleClick(screenLocation: screenLocation)
                } else {
                    self.handleClick(screenLocation: event.locationInWindow)
                }
            }
            return event // pass the event through
        }
    }
    
    func setupHotkeyMonitors() {
        // Load initial cache
        self.cachedHotkeyCode = UInt16(UserDefaults.standard.integer(forKey: "hotkeyCode"))
        self.cachedHotkeyModifiers = NSEvent.ModifierFlags(rawValue: UInt(UserDefaults.standard.integer(forKey: "hotkeyModifiers")))
        
        // Listen for user defaults changes
        NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: .main) { [weak self] _ in
            self?.cachedHotkeyCode = UInt16(UserDefaults.standard.integer(forKey: "hotkeyCode"))
            self?.cachedHotkeyModifiers = NSEvent.ModifierFlags(rawValue: UInt(UserDefaults.standard.integer(forKey: "hotkeyModifiers")))
        }
        
        let checkHotkey: (NSEvent) -> Bool = { [weak self] event in
            guard let self = self else { return false }
            let activeModifiers = event.modifierFlags.intersection([.command, .shift, .control, .option])
            let requiredModifiers = self.cachedHotkeyModifiers.intersection([.command, .shift, .control, .option])
            
            return activeModifiers == requiredModifiers && event.keyCode == self.cachedHotkeyCode
        }
        
        // Accessibility Check for Global Monitor
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        let isTrusted = AXIsProcessTrustedWithOptions(options)
        if !isTrusted {
            print("WARNING: Accessibility permissions are not granted. Global hotkey monitor might fail.")
        }
        
        let handler: (NSEvent) -> Void = { [weak self] event in
            if checkHotkey(event) {
                DispatchQueue.main.async {
                    self?.toggleNotchViaHotkey()
                }
            }
        }
        
        globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown, handler: handler)
        
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if checkHotkey(event) {
                DispatchQueue.main.async {
                    self?.toggleNotchViaHotkey()
                }
                return nil
            }
            return event
        }
    }
    
    func toggleNotchViaHotkey() {
        if notchState.showProgressBar {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                notchState.showProgressBar = false
            }
        } else {
            positionUnderNotch(for: NSScreen.main)
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                notchState.showProgressBar = true
            }
        }
    }
    
    func handleClick(screenLocation: NSPoint) {
        if notchState.showProgressBar {
            // If progress bar is visible, check if click is outside our window to dismiss
            guard let window = self.window else { return }
            let windowFrame = window.frame
            if !windowFrame.contains(screenLocation) {
                DispatchQueue.main.async {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        self.notchState.showProgressBar = false
                    }
                }
            } else {
                // If clicked inside, reset the dismiss timer
                self.notchState.resetDismissTimer()
            }
        } else {
            // If progress bar is hidden, check if click is in the notch region of ANY screen
            if let targetScreen = screenForNotchClick(screenLocation) {
                DispatchQueue.main.async {
                    self.positionUnderNotch(for: targetScreen) // Move to the clicked screen
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        self.notchState.showProgressBar = true
                    }
                }
            }
        }
    }
    
    deinit {
        if let monitor = globalClickMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = localClickMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = globalKeyMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = localKeyMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}

class NotchWindow: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
