# NotchPlay 🎵

**NotchPlay**는 맥북의 노치(또는 상단 메뉴바) 아래에 상주하며 아름다운 턴테이블 인터페이스를 제공하는 macOS 유틸리티 앱입니다. Apple Music과 Spotify의 재생 상태를 동기화하고, 실시간 가사(일본어 후리가나 지원)와 직관적인 제스처 컨트롤을 지원합니다.

## ✨ 주요 기능

- **다이내믹 턴테이블 UI:** 음악의 재생 상태에 맞춰 바늘(Tonearm)이 이동하고 LP판이 회전하는 사실적인 턴테이블 인터페이스. 4가지 커스텀 테마(Technics Gold, Braun SK4, Technics 50th, Rega Minimalist)를 지원합니다.
- **실시간 가사 & 후리가나 자동 변환:** LRCLIB에서 실시간으로 가사를 가져오며, 자연어 처리(NLP)를 통해 일본어 가사 위에 자동으로 발음(후리가나/로마자)을 렌더링합니다.
- **제로 오버헤드 아키텍처:** 배터리를 소모하는 무한 폴링(Polling) 방식 대신, macOS의 `DistributedNotificationCenter`를 활용하여 시스템 푸시 알림 기반으로 작동합니다. (CPU 점유율 0% 유지)
- **제스처 기반 미디어 제어:** 노치 아래로 내려온 앨범 아트를 클릭하여 재생/일시정지하고, 좌우로 마우스를 스와이프하여 이전 곡/다음 곡으로 넘길 수 있습니다.
- **글로벌 단축키:** 어떤 앱을 사용하고 있든 단축키(기본값: `Cmd + Shift + M`) 한 번으로 NotchPlay를 호출할 수 있습니다.
- **다중 모니터 완벽 지원:** 화면에 노치가 없는 구형 맥북이나 클램쉘 모드의 외부 모니터 사용 시, 시스템 메뉴바 하단에 팝오버 형태로 자연스럽게 앵커링됩니다.

## 🛠️ 설치 방법

1. 저장소를 클론(Clone)합니다:
   ```bash
   git clone https://github.com/본인계정명/NotchPlay.git
   ```
2. 빌드 스크립트를 실행합니다:
   ```bash
   cd NotchPlay
   ./build.sh
   ```
3. `build` 폴더 안에 생성된 `NotchPlay.app`을 `/Applications` (응용 프로그램) 폴더로 이동시킵니다.

## ⚠️ 요구 사항 및 권한

- macOS 12.0 (Monterey) 이상
- **손쉬운 사용 및 자동화 권한:** 글로벌 단축키 감지 및 Apple Music / Spotify 제어를 위해 '손쉬운 사용(Accessibility)'과 'AppleEvents' 권한 허용이 필수적으로 요구됩니다. 앱을 처음 실행할 때 나타나는 안내에 따라 권한을 허용해 주세요.

## 💻 기술 스택

- **SwiftUI** & **AppKit** (macOS 네이티브 UI)
- **Combine** (반응형 상태 관리)
- **AppleScript** & **DistributedNotificationCenter** (미디어 통합 제어)
- **NaturalLanguage** 프레임워크 (NLP 기반 후리가나 파싱)

## 📄 라이선스
MIT License
