import re

with open('src/NotchView.swift', 'r') as f:
    content = f.read()

pattern = r"struct TurntableView: View \{\n    let artworkImage: NSImage\?\n    let isPlaying: Bool\n    let theme: TurntableTheme\n"
replacement = """struct TurntableView: View {
    let artworkImage: NSImage?
    let isPlaying: Bool
    let theme: TurntableTheme
    var onPlayPause: () -> Void = {}
    var onNext: () -> Void = {}
    var onPrevious: () -> Void = {}
"""
content = re.sub(pattern, replacement, content)

with open('src/NotchView.swift', 'w') as f:
    f.write(content)
