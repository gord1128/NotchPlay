import SwiftUI
import AppKit
import ServiceManagement
import Combine
import SceneKit

struct LiquidGlassModifier: ViewModifier {
    var theme: TurntableTheme
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    VisualEffectView(material: .popover, blendingMode: .behindWindow, state: .active, appearanceName: theme.visualAppearance)
                    
                    // Liquid depth / inner glow
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(theme.colorScheme == .dark ? 0.15 : 0.6),
                                    Color.clear,
                                    Color.black.opacity(theme.colorScheme == .dark ? 0.4 : 0.05)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .blendMode(.overlay)
                        
                    theme.backgroundTint.opacity(0.3)
                }
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                // Glossy refracting edges
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.8),
                                    Color.white.opacity(0.1),
                                    Color.white.opacity(0.1),
                                    Color.white.opacity(0.3)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                // Diffuse ambient shadows
                .shadow(color: Color.black.opacity(0.25), radius: 25, x: 0, y: 15)
                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
            )
            .environment(\.colorScheme, theme.colorScheme)
    }
}

extension View {
    func liquidGlassBackground(theme: TurntableTheme) -> some View {
        self.modifier(LiquidGlassModifier(theme: theme))
    }
}

enum TurntableTheme: String, CaseIterable, Identifiable {
    case technicsGold = "Technics Gold"
    case braunVintage = "Braun SK4 Vintage"
    case technicsAnni = "Technics 50th"
    case regaModern = "Rega Minimalist"
    var id: String { self.rawValue }
}

extension TurntableTheme {
    var primaryTextColor: Color {
        Color.primary
    }
    
    var secondaryTextColor: Color {
        Color.secondary
    }
    
    var visualAppearance: NSAppearance.Name {
        self == .braunVintage ? .vibrantLight : .vibrantDark
    }
    
    var colorScheme: ColorScheme {
        self == .braunVintage ? .light : .dark
    }
    
    var backgroundTint: Color {
        Color.clear // 애플 HIG 규격을 위해 인위적인 배경 틴트는 제거
    }
    
    var progressTrackColor: Color {
        self == .braunVintage ? Color.black.opacity(0.1) : Color.white.opacity(0.2)
    }
    
    var progressFillColor: Color {
        switch self {
        case .technicsGold: return Color(red: 0.85, green: 0.65, blue: 0.13) // Gold
        case .braunVintage: return Color(red: 0.8, green: 0.2, blue: 0.2) // Vintage Red
        case .technicsAnni: return Color(red: 0.2, green: 0.4, blue: 0.8) // Blue
        case .regaModern: return Color(red: 0.1, green: 0.8, blue: 0.3) // Bright Green
        }
    }
}

struct NotchView: View {
    @ObservedObject var notchState: NotchState
    @StateObject private var systemMediaManager = SystemMediaManager()
    @StateObject private var systemAudio = SystemAudioManager()
    @State private var showSettings = false
    @AppStorage("TurntableTheme") private var currentTheme: TurntableTheme = .technicsGold
    
    @AppStorage("hotkeyCode") private var hotkeyCode: Int = 46
    @AppStorage("hotkeyModifiers") private var hotkeyModifiers: Int = Int(NSEvent.ModifierFlags.command.rawValue | NSEvent.ModifierFlags.shift.rawValue)
    @State private var isRecordingHotkey = false
    @State private var hoveredProgress: Double? = nil
    
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @State private var hasAccessibilityAccess = true
    
    // Default 5 seconds auto-dismiss timer is in NotchState
    
    var body: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(width: 200, height: 32)
            
            if notchState.showProgressBar {
                VStack(spacing: 8) {
                    // Main player UI
                    VStack(spacing: 8) {
                        // Turntable
                        HStack {
                            Spacer()
                            if systemMediaManager.artworkImage != nil {
                                TurntableView(artworkImage: systemMediaManager.artworkImage, isPlaying: systemMediaManager.isPlaying, theme: currentTheme, onPlayPause: {
                                    systemMediaManager.playPause()
                                }, onNext: {
                                    systemMediaManager.nextTrack()
                                }, onPrevious: {
                                    systemMediaManager.previousTrack()
                                })
                                .frame(width: 176, height: 100)
                                .clipped()
                            } else {
                                TurntableView(artworkImage: nil, isPlaying: false, theme: currentTheme)
                                    .frame(width: 140, height: 140)
                                    .frame(width: 176, height: 100)
                                    .clipped()
                            }
                            Spacer()
                        }
                        
                        // Controls section
                        VStack(alignment: .center, spacing: 6) {
                            if systemMediaManager.isMediaRunning {
                                HStack(alignment: .center, spacing: 6) {
                                    VStack(alignment: .center, spacing: 2) {
                                        Text(systemMediaManager.trackName)
                                            .font(.system(size: 14, weight: .bold, design: .rounded))
                                            .foregroundColor(currentTheme.primaryTextColor)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.8)
                                        Text(systemMediaManager.artistName)
                                            .font(.system(size: 11, weight: .medium, design: .rounded))
                                            .foregroundColor(currentTheme.secondaryTextColor)
                                            .lineLimit(1)
                                    }

                                }
                                
                                // Playback controls
                                HStack(spacing: 16) {
                                    Button(action: {
                                        systemMediaManager.previousTrack()
                                    }) {
                                        Image(systemName: "backward.fill")
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .buttonStyle(AppleHIGButtonStyle(size: 32, theme: currentTheme))
                                    
                                    Button(action: {
                                        systemMediaManager.playPause()
                                    }) {
                                        Image(systemName: systemMediaManager.isPlaying ? "pause.fill" : "play.fill")
                                            .font(.system(size: 20, weight: .medium))
                                    }
                                    .buttonStyle(AppleHIGButtonStyle(size: 44, theme: currentTheme))
                                    
                                    Button(action: {
                                        systemMediaManager.nextTrack()
                                    }) {
                                        Image(systemName: "forward.fill")
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .buttonStyle(AppleHIGButtonStyle(size: 32, theme: currentTheme))
                                }
                                .padding(.vertical, 0)
                                
                                // Progress bar with time
                                HStack {
                                    Text(formatTime(systemMediaManager.progress * systemMediaManager.durationSeconds))
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(currentTheme.secondaryTextColor)
                                        .frame(width: 30, alignment: .leading)
                                    
                                    GeometryReader { geometry in
                                        ZStack(alignment: .leading) {
                                            Capsule()
                                                .fill(currentTheme.progressTrackColor)
                                                .frame(height: 4)
                                            Capsule()
                                                .fill(currentTheme.progressFillColor)
                                                .frame(width: max(0, geometry.size.width * CGFloat(systemMediaManager.progress)), height: 4)
                                                .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.7), value: systemMediaManager.progress)
                                        }
                                        .frame(height: 20)
                                        .contentShape(Rectangle())
                                        .gesture(
                                            DragGesture(minimumDistance: 0)
                                                .onChanged { value in
                                                    systemMediaManager.isDraggingProgress = true
                                                    let percent = min(max(0, value.location.x / geometry.size.width), 1)
                                                    systemMediaManager.progress = percent
                                                }
                                                .onEnded { value in
                                                    systemMediaManager.isDraggingProgress = false
                                                    let percent = min(max(0, value.location.x / geometry.size.width), 1)
                                                    systemMediaManager.seek(to: Double(percent))
                                                }
                                        )
                                    }
                                    .frame(height: 20)
                                    
                                    Text(formatTime(systemMediaManager.durationSeconds))
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(currentTheme.secondaryTextColor)
                                        .frame(width: 30, alignment: .trailing)
                                }
                                
                                // Lyrics Sync Display
                                if !systemMediaManager.currentLyric.isEmpty {
                                    VStack(spacing: 2) {
                                        Text(systemMediaManager.currentLyric)
                                            .font(.system(size: 11, weight: .medium, design: .rounded))
                                            .foregroundColor(currentTheme.primaryTextColor.opacity(0.85))
                                            .multilineTextAlignment(.center)
                                            .lineLimit(2)
                                            .minimumScaleFactor(0.8)
                                            .fixedSize(horizontal: false, vertical: true)
                                        
                                        if !systemMediaManager.currentRomaji.isEmpty {
                                            Text(systemMediaManager.currentRomaji)
                                                .font(.system(size: 9, weight: .regular, design: .rounded))
                                                .foregroundColor(currentTheme.secondaryTextColor.opacity(0.8))
                                                .multilineTextAlignment(.center)
                                                .lineLimit(2)
                                                .minimumScaleFactor(0.7)
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(currentTheme == .braunVintage ? Color.black.opacity(0.05) : Color.white.opacity(0.1))
                                    )
                                    .padding(.top, 4)
                                    .padding(.horizontal, 10)
                                    .id(systemMediaManager.currentLyric) // Force new view creation for transition
                                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                                }

                            } else if systemMediaManager.activePlayer == "None" {
                                // Idle State
                                VStack(spacing: 12) {
                                    Text("No media playing")
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                        .foregroundColor(.gray)
                                    
                                    HStack(spacing: 24) {
                                        Button(action: {
                                            systemMediaManager.launchApp(app: .music)
                                            notchState.resetDismissTimer()
                                        }) {
                                            VStack {
                                                Image(systemName: "music.note")
                                                    .font(.system(size: 20))
                                                    .foregroundColor(.pink)
                                                    .frame(width: 44, height: 44)
                                                    .background(Color.white.opacity(0.1))
                                                    .clipShape(Circle())
                                                Text("Music")
                                                    .font(.system(size: 10, weight: .medium))
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        
                                        Button(action: {
                                            systemMediaManager.launchApp(app: .spotify)
                                            notchState.resetDismissTimer()
                                        }) {
                                            VStack {
                                                Image(systemName: "speaker.wave.3.fill")
                                                    .font(.system(size: 20))
                                                    .foregroundColor(.green)
                                                    .frame(width: 44, height: 44)
                                                    .background(Color.white.opacity(0.1))
                                                    .clipShape(Circle())
                                                Text("Spotify")
                                                    .font(.system(size: 10, weight: .medium))
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.top, 10)
                            } else {
                                Text("No Media Playing")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundColor(currentTheme.secondaryTextColor)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(width: 200)
                    .liquidGlassBackground(theme: currentTheme)
                    .overlay(alignment: .topTrailing) {
                        Button(action: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                showSettings.toggle()
                            }
                        }) {
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(showSettings ? currentTheme.primaryTextColor : currentTheme.secondaryTextColor.opacity(0.6))
                                .font(.system(size: 12))
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.top, 16)
                        .padding(.trailing, 16)
                    }
                    
                    // Settings panel
                    if showSettings {
                        VStack(spacing: 8) {
                            // Volume sliders
                            VStack(spacing: 5) {
                                // App Volume (Spotify or Apple Music)
                            HStack(spacing: 6) {
                                Image(systemName: "hifispeaker.fill")
                                    .foregroundColor(currentTheme.secondaryTextColor)
                                    .font(.system(size: 8))
                                    .frame(width: 12)
                                
                                Slider(value: Binding(
                                    get: { systemMediaManager.appVolume },
                                    set: { newValue in
                                        systemMediaManager.appVolume = newValue
                                        systemMediaManager.setAppVolume(to: newValue, isFinished: false)
                                    }
                                ), in: 0...1, onEditingChanged: { editing in
                                    if !editing {
                                        systemMediaManager.setAppVolume(to: systemMediaManager.appVolume, isFinished: true)
                                    }
                                })
                                .accentColor(currentTheme.progressFillColor)
                                .frame(height: 20)
                                
                                Image(systemName: "hifispeaker.2.fill")
                                    .foregroundColor(currentTheme.secondaryTextColor)
                                    .font(.system(size: 8))
                                    .frame(width: 12)
                            }
                            
                            // System Volume
                                HStack(spacing: 6) {
                                    Image(systemName: "speaker.fill")
                                        .foregroundColor(currentTheme.secondaryTextColor)
                                        .font(.system(size: 8))
                                        .frame(width: 12)
                                    
                                    Slider(value: Binding(
                                        get: { systemAudio.volume },
                                        set: { newValue in
                                            systemAudio.volume = newValue
                                            systemAudio.setVolume(to: newValue, isFinished: false)
                                        }
                                    ), in: 0...1, onEditingChanged: { editing in
                                        if !editing {
                                            systemAudio.setVolume(to: systemAudio.volume, isFinished: true)
                                        }
                                    })
                                    .accentColor(currentTheme.primaryTextColor)
                                    .frame(height: 20)
                                    
                                    Image(systemName: "speaker.wave.3.fill")
                                        .foregroundColor(currentTheme.secondaryTextColor)
                                        .font(.system(size: 8))
                                        .frame(width: 12)
                                }
                            }
                            
                            Divider().background(currentTheme.secondaryTextColor.opacity(0.3))
                            
                            VStack(spacing: 12) {
                                // Launch at Login Toggle
                                HStack {
                                    Text("Launch at Login")
                                        .font(.system(size: 11, weight: .medium, design: .rounded))
                                        .foregroundColor(currentTheme.primaryTextColor)
                                    Spacer()
                                    Toggle("", isOn: Binding(get: {
                                        launchAtLogin
                                    }, set: { newValue in
                                        launchAtLogin = newValue
                                        do {
                                            if newValue {
                                                if SMAppService.mainApp.status == .notRegistered {
                                                    try SMAppService.mainApp.register()
                                                }
                                            } else {
                                                try SMAppService.mainApp.unregister()
                                            }
                                        } catch {
                                            print("Failed to change SMAppService: \(error)")
                                        }
                                    }))
                                    .labelsHidden()
                                    .toggleStyle(SwitchToggleStyle(tint: currentTheme.primaryTextColor))
                                }
                                .padding(.horizontal, 4)
                                
                                // Theme Selector
                                HStack {
                                    Text("Theme")
                                        .font(.system(size: 11, weight: .medium, design: .rounded))
                                        .foregroundColor(currentTheme.primaryTextColor)
                                    Spacer()
                                    
                                    Picker("", selection: $currentTheme) {
                                        ForEach(TurntableTheme.allCases) { theme in
                                            Text(theme.rawValue)
                                                .tag(theme)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .labelsHidden()
                                    .frame(width: 100)
                                    .font(.system(size: 9))
                                }
                                .padding(.horizontal, 4)
                                
                                // Hotkey Selector
                                HStack {
                                    Text("Global Hotkey")
                                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                                        .foregroundColor(currentTheme.primaryTextColor)
                                    Spacer()
                                    
                                    Button(action: {
                                        isRecordingHotkey.toggle()
                                    }) {
                                        Text(isRecordingHotkey ? "Recording..." : HotkeyHelper.string(for: UInt16(hotkeyCode), modifiers: NSEvent.ModifierFlags(rawValue: UInt(hotkeyModifiers))))
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundColor(currentTheme.primaryTextColor)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 3)
                                            .background(isRecordingHotkey ? currentTheme.progressFillColor.opacity(0.8) : Color.white.opacity(0.1))
                                            .cornerRadius(4)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .background(
                                        HotkeyRecorderView(isRecording: $isRecordingHotkey)
                                            .frame(width: 0, height: 0)
                                            .opacity(0)
                                    )
                                }
                                .padding(.horizontal, 4)
                                
                                Button(action: {
                                    NSApplication.shared.terminate(nil)
                                }) {
                                    HStack {
                                        Image(systemName: "power")
                                            .foregroundColor(.red)
                                            .font(.system(size: 10))
                                        Text("Quit NotchPlay")
                                            .font(.system(size: 9, weight: .bold, design: .rounded))
                                            .foregroundColor(.red)
                                        Spacer()
                                        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                                            Text("v\(version)")
                                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                                                .foregroundColor(currentTheme.secondaryTextColor)
                                        }
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.horizontal, 4)
                            }
                            .padding(.vertical, 4)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(width: 200)
                        .liquidGlassBackground(theme: currentTheme)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .padding(.top, 4)
                .transition(
                    .asymmetric(
                        insertion: .scale(scale: 0.5, anchor: .top).combined(with: .opacity),
                        removal: .scale(scale: 0.5, anchor: .top).combined(with: .opacity)
                    )
                )
            }
            
            Spacer()
        }
        .frame(width: 260, height: 500, alignment: .top)
        .onHover { isHovering in
            notchState.isHovering = isHovering
        }
    }
    
    func formatTime(_ seconds: Double) -> String {
        let totalSeconds = Int(max(0, seconds))
        let mins = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Visual Effect View for Native macOS Glass
struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    var state: NSVisualEffectView.State = .active
    var appearanceName: NSAppearance.Name? = nil

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        if let appearanceName = appearanceName {
            view.appearance = NSAppearance(named: appearanceName)
        }
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
        if let appearanceName = appearanceName {
            nsView.appearance = NSAppearance(named: appearanceName)
        } else {
            nsView.appearance = nil
        }
    }
}

// MARK: - App Icon Background
struct AppIconBackground: View {
    var theme: TurntableTheme
    
    var body: some View {
        ZStack {
            // 1. App Icon Base Gradient
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: backgroundColors(for: theme)),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            // 2. Top Inner Highlight
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(
                    LinearGradient(
                        gradient: Gradient(colors: highlightColors(for: theme)),
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1.5
                )
            
            // 3. Subtle outer rim
            RoundedRectangle(cornerRadius: 24)
                .stroke(rimColor(for: theme), lineWidth: 0.5)
        }
        .shadow(color: shadowColor(for: theme), radius: 10, x: 0, y: 6)
    }
    
    func backgroundColors(for theme: TurntableTheme) -> [Color] {
        switch theme {
        case .technicsGold:
            return [Color(white: 0.25).opacity(0.95), Color(white: 0.10).opacity(0.95)]
        case .braunVintage:
            return [Color(red: 0.94, green: 0.93, blue: 0.90).opacity(0.98), Color(red: 0.88, green: 0.86, blue: 0.82).opacity(0.98)]
        case .technicsAnni:
            return [Color(white: 0.15).opacity(0.95), Color(white: 0.05).opacity(0.95)]
        case .regaModern:
            return [Color(white: 0.18).opacity(0.98), Color(white: 0.18).opacity(0.98)]
        }
    }
    
    func highlightColors(for theme: TurntableTheme) -> [Color] {
        switch theme {
        case .braunVintage:
            return [Color.white.opacity(0.8), Color.white.opacity(0.0), Color.black.opacity(0.1)]
        default:
            return [Color.white.opacity(0.35), Color.white.opacity(0.0), Color.black.opacity(0.5)]
        }
    }
    
    func rimColor(for theme: TurntableTheme) -> Color {
        switch theme {
        case .braunVintage:
            return Color.black.opacity(0.15)
        default:
            return Color.black.opacity(0.8)
        }
    }
    
    func shadowColor(for theme: TurntableTheme) -> Color {
        switch theme {
        case .braunVintage:
            return Color.black.opacity(0.3)
        default:
            return Color.black.opacity(0.6)
        }
    }
}

// MARK: - Apple HIG Button Style
struct AppleHIGButtonStyle: ButtonStyle {
    var size: CGFloat
    var theme: TurntableTheme
    @State private var isHovered = false
    
    func makeBody(configuration: Configuration) -> some View {
        let baseOpacity: Double = theme == .braunVintage ? 0.0 : 0.0
        let hoverOpacity: Double = theme == .braunVintage ? 0.08 : 0.15
        let pressedOpacity: Double = theme == .braunVintage ? 0.15 : 0.3
        let color: Color = theme == .braunVintage ? .black : .white
        
        let currentOpacity = configuration.isPressed ? pressedOpacity : (isHovered ? hoverOpacity : baseOpacity)
        
        configuration.label
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(color.opacity(currentOpacity))
            )
            .foregroundColor(theme.primaryTextColor)
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
            .animation(.easeOut(duration: 0.2), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

struct ThemeAttributes {
    let baseImage: String
    let armImage: String
    let platterX: CGFloat
    let platterY: CGFloat
    let recordSize: CGFloat
    let shadowSize: CGFloat
    let armWidth: CGFloat
    let armHeight: CGFloat
    let anchorX: CGFloat
    let anchorY: CGFloat
    let restAngle: Double
    let playAngle: Double
    let armX: CGFloat
    let armY: CGFloat
}

extension TurntableTheme {
    var attributes: ThemeAttributes {
        switch self {
        case .technicsGold:
            return ThemeAttributes(
                baseImage: "turntable_bg.png", armImage: "tonearm.png",
                platterX: 57.0, platterY: 68.0, recordSize: 82, shadowSize: 84,
                armWidth: 110, armHeight: 110, anchorX: 0.5, anchorY: 0.25,
                restAngle: 0, playAngle: 38, armX: 114, armY: 70.5
            )
        case .braunVintage:
            return ThemeAttributes(
                baseImage: "turntable_bg_braun.png", armImage: "tonearm_braun.png",
                platterX: 88.9, platterY: 69.5, recordSize: 70, shadowSize: 72,
                armWidth: 80, armHeight: 80, anchorX: 0.5, anchorY: 0.18,
                restAngle: 0, playAngle: -40, armX: 31.4, armY: 70.2
            )
        case .technicsAnni:
            return ThemeAttributes(
                baseImage: "turntable_bg_anni.png", armImage: "tonearm.png",
                platterX: 57.7, platterY: 67.8, recordSize: 82, shadowSize: 84,
                armWidth: 110, armHeight: 110, anchorX: 0.5, anchorY: 0.25,
                restAngle: 0, playAngle: 40, armX: 114, armY: 70.5
            )
        case .regaModern:
            return ThemeAttributes(
                baseImage: "turntable_bg_rega.png", armImage: "tonearm_rega.png",
                platterX: 53.9, platterY: 69.7, recordSize: 80, shadowSize: 82,
                armWidth: 90, armHeight: 90, anchorX: 0.5, anchorY: 0.18,
                restAngle: 0, playAngle: 22, armX: 105, armY: 53.8
            )
        }
    }
}

struct TurntableView: View {
    let artworkImage: NSImage?
    let isPlaying: Bool
    let theme: TurntableTheme
    var onPlayPause: () -> Void = {}
    var onNext: () -> Void = {}
    var onPrevious: () -> Void = {}
    
    @State private var rotation: Double = 0
    let timer = Timer.publish(every: 1.0/60.0, on: .main, in: .common).autoconnect()
    
    var attrs: ThemeAttributes { theme.attributes }
    
    var body: some View {
        let a = attrs
        
        // Base View (Strictly 140x140)
        Group {
            if let path = Bundle.main.path(forResource: a.baseImage, ofType: nil),
               let bgImage = NSImage(contentsOfFile: path) {
                Image(nsImage: bgImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(8)
            } else {
                Color.black
            }
        }
        .frame(width: 140, height: 140)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(gradient: Gradient(colors: [Color.white.opacity(0.2), Color.clear]), startPoint: .topLeading, endPoint: .bottomTrailing))
                .blendMode(.screen)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.progressFillColor.opacity(0.1))
                .blendMode(.overlay)
        )
        .overlay(
            ZStack(alignment: .topLeading) {
                // Spinning Record
                ZStack {
                    Circle().fill(Color.black.opacity(0.4)).frame(width: a.shadowSize, height: a.shadowSize).shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 4)
                    
                    if let image = artworkImage {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: a.recordSize, height: a.recordSize)
                            .clipShape(Circle())
                    } else {
                        Circle().fill(Color(white: 0.1)).frame(width: a.recordSize, height: a.recordSize)
                    }

                    Circle()
                        .fill(RadialGradient(gradient: Gradient(colors: [Color.black.opacity(0.2), Color.black.opacity(0.5), Color.black.opacity(0.3), Color.black.opacity(0.7)]), center: .center, startRadius: 10, endRadius: 40))
                        .frame(width: a.recordSize, height: a.recordSize)
                    
                    Circle()
                        .fill(AngularGradient(gradient: Gradient(colors: [.white.opacity(0.0), .white.opacity(0.4), .white.opacity(0.0), .white.opacity(0.4), .white.opacity(0.0)]), center: .center, startAngle: .degrees(0), endAngle: .degrees(360)))
                        .frame(width: a.recordSize, height: a.recordSize)
                        .blendMode(.screen)
                    
                    Circle().fill(Color.black).frame(width: 4, height: 4)
                }
                .rotationEffect(.degrees(rotation))
                .position(x: a.platterX, y: a.platterY)
                
                // Photorealistic Tonearm
                if let path = Bundle.main.path(forResource: a.armImage, ofType: nil),
                   let armImage = NSImage(contentsOfFile: path) {
                    Image(nsImage: armImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: a.armWidth, height: a.armHeight)
                        .shadow(color: .black.opacity(0.4), radius: 8, x: -2, y: 6)
                        .rotationEffect(.degrees(isPlaying ? a.playAngle : a.restAngle), anchor: UnitPoint(x: a.anchorX, y: a.anchorY))
                        .animation(.interactiveSpring(response: 0.35, dampingFraction: 0.7, blendDuration: 0), value: isPlaying)
                        .position(x: a.armX, y: a.armY)
                }
            },
            alignment: .topLeading
        )
        .onReceive(timer) { _ in
            if isPlaying {
                rotation += 1.5
                if rotation >= 360 { rotation -= 360 }
            }
        }
        // F-01: Gesture Integration
        .onTapGesture {
            onPlayPause()
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
    }
}
