import SwiftUI
import AppKit

struct HotkeyRecorderView: NSViewRepresentable {
    @Binding var isRecording: Bool
    
    func makeNSView(context: Context) -> HotkeyRecorderNSView {
        let view = HotkeyRecorderNSView()
        view.onRecordingDidEnd = {
            self.isRecording = false
        }
        return view
    }
    
    func updateNSView(_ nsView: HotkeyRecorderNSView, context: Context) {
        if isRecording {
            nsView.window?.makeFirstResponder(nsView)
            nsView.isRecording = true
        } else {
            nsView.isRecording = false
        }
    }
}

class HotkeyRecorderNSView: NSView {
    var isRecording = false
    var onRecordingDidEnd: (() -> Void)?
    
    override var acceptsFirstResponder: Bool { return true }
    
    override func becomeFirstResponder() -> Bool {
        return true
    }
    
    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }
        
        let modifiers = event.modifierFlags.intersection([.command, .shift, .control, .option])
        let keyCode = event.keyCode
        
        // Save to UserDefaults
        UserDefaults.standard.set(Int(keyCode), forKey: "hotkeyCode")
        UserDefaults.standard.set(Int(modifiers.rawValue), forKey: "hotkeyModifiers")
        
        onRecordingDidEnd?()
    }
    
    override func flagsChanged(with event: NSEvent) {
        // We only care about keydown for final binding, but we could visualize modifiers here if needed.
    }
}
