import re

# 1. Fix SystemMediaManager
with open('src/SystemMediaManager.swift', 'r') as f:
    smm = f.read()

smm = smm.split('    // F-01: Playback Controls')[0].strip() + "\n}\n"

with open('src/SystemMediaManager.swift', 'w') as f:
    f.write(smm)

# 2. Fix NotchView
with open('src/NotchView.swift', 'r') as f:
    nv = f.read()

# Add closures to TurntableView
pattern_turntable = r"(let theme: TurntableTheme\n)"
replacement_turntable = r"\1    var onPlayPause: () -> Void = {}\n    var onNext: () -> Void = {}\n    var onPrevious: () -> Void = {}\n"
nv = re.sub(pattern_turntable, replacement_turntable, nv, count=1)

# Modify gesture inside TurntableView
pattern_gesture = r"SystemMediaManager\.shared\.playPause\(\).*?SystemMediaManager\.shared\.nextTrack\(\).*?SystemMediaManager\.shared\.previousTrack\(\)"
replacement_gesture = """onPlayPause()
        }
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    if value.translation.width < 0 {
                        onNext()
                    } else if value.translation.width > 0 {
                        onPrevious()
                    }
                }
        )
//"""
# Actually, the python regex with re.sub for dotall is safer if I just write it exactly
