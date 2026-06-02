import re

with open('src/NotchWindowController.swift', 'r') as f:
    content = f.read()

pattern = r"func positionUnderNotch\(for targetScreen: NSScreen\? = nil\) \{.*?\n    \}"
replacement = """func positionUnderNotch(for targetScreen: NSScreen? = nil) {
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
    }"""
content = re.sub(pattern, replacement, content, flags=re.DOTALL)

with open('src/NotchWindowController.swift', 'w') as f:
    f.write(content)
