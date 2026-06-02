import re

with open('src/NotchView.swift', 'r') as f:
    content = f.read()

# Add state
pattern1 = r"(@AppStorage\(\"launchAtLogin\"\) private var launchAtLogin = false)"
replacement1 = r"""\1
    @State private var hasAccessibilityAccess = true"""
content = re.sub(pattern1, replacement1, content)

# Add onAppear check
pattern2 = r"(\.onAppear \{\n.*?systemMediaManager\.start\(\)\n.*?\})"
replacement2 = r"""\1
        .onAppear {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false] as CFDictionary
            hasAccessibilityAccess = AXIsProcessTrustedWithOptions(options)
        }"""
content = re.sub(pattern2, replacement2, content, flags=re.DOTALL)

# Add Overlay
pattern3 = r"(if notchState\.showProgressBar \{.*?VStack.*?\}.*?\.padding\(\.top\, 20\)\n                \})"
replacement3 = r"""\1
                
                // F-03: Onboarding Overlay
                if !hasAccessibilityAccess && notchState.showProgressBar {
                    VStack(spacing: 15) {
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        
                        Text("권한 허용 필요")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("NotchPlay가 단축키와 미디어를 제어하려면\n손쉬운 사용 권한이 필요합니다.")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                        
                        Button("설정 열기") {
                            let prefpaneUrl = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                            NSWorkspace.shared.open(prefpaneUrl)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(12)
                        .foregroundColor(.white)
                        
                        Button("확인 완료 (새로고침)") {
                            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false] as CFDictionary
                            hasAccessibilityAccess = AXIsProcessTrustedWithOptions(options)
                        }
                        .font(.caption)
                        .foregroundColor(.gray)
                    }
                    .frame(width: 240, height: 400)
                    .background(Color.black.opacity(0.95))
                    .cornerRadius(24)
                    .padding(.top, 20)
                    .transition(.opacity)
                }
"""
content = re.sub(pattern3, replacement3, content, flags=re.DOTALL)

with open('src/NotchView.swift', 'w') as f:
    f.write(content)
