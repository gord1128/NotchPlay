import re

with open('src/NotchView.swift', 'r') as f:
    content = f.read()

# Add gesture to TurntableView
pattern = r"(\.onReceive\(timer\) \{ \_ in\n.*?\}\n        \})"
replacement = r"""\1
        // F-01: Gesture Integration
        .onTapGesture {
            SystemMediaManager.shared.playPause()
        }
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    if value.translation.width < 0 {
                        SystemMediaManager.shared.nextTrack()
                    } else if value.translation.width > 0 {
                        SystemMediaManager.shared.previousTrack()
                    }
                }
        )"""

content = re.sub(pattern, replacement, content, flags=re.DOTALL)

with open('src/NotchView.swift', 'w') as f:
    f.write(content)
