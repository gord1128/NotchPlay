#!/bin/bash
set -e

# NotchPlay Perfect CI/CD Release Pipeline
# (Git Tagging + SemVer + Automated Changelog + Isolated Build)

echo "🚀 NotchPlay 완벽한 릴리즈 파이프라인을 시작합니다..."

# 1. 시맨틱 버저닝 및 이전 태그 확인
VERSION_FILE=".version"

if [ ! -f "$VERSION_FILE" ]; then
    echo "1.0.0" > "$VERSION_FILE"
fi

CURRENT_VERSION=$(cat "$VERSION_FILE")
IFS='.' read -r major minor patch <<< "$CURRENT_VERSION"

# 버전 10 단위 올림(Rollover) 규칙 절대 엄수
new_patch=$((patch + 1))
if [ "$new_patch" -ge 10 ]; then
    new_patch=0
    minor=$((minor + 1))
fi

if [ "$minor" -ge 10 ]; then
    minor=0
    major=$((major + 1))
fi

NEW_VERSION="${major}.${minor}.${new_patch}"
TAG_VERSION="v$NEW_VERSION"
PREVIOUS_TAG="v$CURRENT_VERSION"

echo "$NEW_VERSION" > "$VERSION_FILE"
echo "🏷️ 이번 배포 버전: $TAG_VERSION (이전: $PREVIOUS_TAG)"

# 2. 코드 백업 및 커밋
echo "📦 1. 변경된 코드를 백업합니다..."
git add .
CURRENT_TIME=$(date "+%Y-%m-%d %H:%M:%S")

if ! git diff-index --quiet HEAD; then
    git commit -m "🚀 Release: $TAG_VERSION - Auto-sync at $CURRENT_TIME"
else
    echo "ℹ️ 커밋할 변경사항이 없습니다."
fi

# 3. 릴리즈 노트(Changelog) 자동 생성
# 이전 태그가 존재하는지 확인 후, 커밋 로그 추출
CHANGELOG_FILE="changelog_temp.md"

# 만약 AI_SUMMARY.md 파일이 존재하면 PM 요약 노트를 삽입
if [ -f "AI_SUMMARY.md" ]; then
    cat "AI_SUMMARY.md" > "$CHANGELOG_FILE"
    echo "" >> "$CHANGELOG_FILE"
    echo "---" >> "$CHANGELOG_FILE"
    echo "" >> "$CHANGELOG_FILE"
else
    echo "## 🚀 What's New in $TAG_VERSION" > "$CHANGELOG_FILE"
    echo "" >> "$CHANGELOG_FILE"
fi

if git rev-parse "$PREVIOUS_TAG" >/dev/null 2>&1; then
    echo "이전 버전($PREVIOUS_TAG) 이후의 변경사항을 추출합니다..."
    git log ${PREVIOUS_TAG}..HEAD --pretty=format:"- %s" >> "$CHANGELOG_FILE"
else
    echo "첫 번째 정식 태그이거나 이전 태그를 찾을 수 없습니다. 모든 내역을 포함합니다."
    git log -n 5 --pretty=format:"- %s" >> "$CHANGELOG_FILE"
fi

echo "" >> "$CHANGELOG_FILE"
echo "*자동 빌드 및 배포 일시: $CURRENT_TIME*" >> "$CHANGELOG_FILE"

# 4. Git Tag 생성 및 Push
echo "🔖 2. Git Tag 생성 및 원격 저장소 업로드..."
git tag -a "$TAG_VERSION" -m "Release $TAG_VERSION"
git push origin main
git push origin "$TAG_VERSION"

# 5. 격리된 환경에서 빌드 (--release 플래그 사용)
echo "🔨 3. 릴리즈용으로 앱을 안전하게 빌드합니다..."
./build.sh --release

# 6. 앱 패키징 (.app -> .dmg)
echo "💽 4. 빌드된 앱을 macOS 표준 디스크 이미지(DMG)로 패키징합니다..."
DMG_NAME="NotchPlay_${TAG_VERSION}.dmg"
rm -f NotchPlay_v*.dmg

# hdiutil을 사용하여 build/NotchPlay.app을 DMG로 변환
hdiutil create -volname "NotchPlay" -srcfolder build/NotchPlay.app -ov -format UDZO "$DMG_NAME"

# 7. GitHub Release 배포 (자동 생성된 Changelog 사용)
echo "☁️ 5. GitHub Releases에 정식 배포 중..."
gh release create "$TAG_VERSION" "$DMG_NAME" -t "NotchPlay Release $TAG_VERSION" -F "$CHANGELOG_FILE"

# 임시 파일 정리
rm -f "$CHANGELOG_FILE"

echo "✅ 완벽한 릴리즈 파이프라인이 성공적으로 끝났습니다! ($TAG_VERSION)"
