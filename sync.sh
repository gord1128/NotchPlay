#!/bin/bash

# NotchPlay GitHub Auto-Sync & Semantic Versioning Release Script
# 코드 백업과 동시에 빌드 및 GitHub Releases 업로드를 수행합니다. (SemVer 기반)

echo "🚀 NotchPlay GitHub 자동 동기화 및 릴리즈 파이프라인을 시작합니다..."

# 1. Semantic Versioning 관리 로직
VERSION_FILE=".version"

# 버전 파일이 없으면 초기 버전 1.0.0으로 생성
if [ ! -f "$VERSION_FILE" ]; then
    echo "1.0.0" > "$VERSION_FILE"
fi

# 현재 버전 읽기
CURRENT_VERSION=$(cat "$VERSION_FILE")

# 버전을 .(점)을 기준으로 분리 (예: 1 0 0)
IFS='.' read -r major minor patch <<< "$CURRENT_VERSION"

# 패치(patch) 버전 1 증가
new_patch=$((patch + 1))
NEW_VERSION="${major}.${minor}.${new_patch}"
TAG_VERSION="v$NEW_VERSION"

# 새 버전을 파일에 저장 (다음 배포를 위해)
echo "$NEW_VERSION" > "$VERSION_FILE"

echo "🏷️ 이번 배포 버전: $TAG_VERSION (이전: v$CURRENT_VERSION)"

# 2. 깃허브 코드 동기화 (Push)
echo "📦 1. 변경된 코드를 백업합니다..."
git add .
CURRENT_TIME=$(date "+%Y-%m-%d %H:%M:%S")

# 변경사항이 있을 때만 커밋
if ! git diff-index --quiet HEAD; then
    git commit -m "🚀 Release: $TAG_VERSION - Auto-sync at $CURRENT_TIME"
    git push origin main
else
    echo "ℹ️ 변경된 코드가 없습니다. 버전만 올리고 릴리즈를 진행합니다."
fi

# 3. 최신 코드로 빌드 진행
echo "🔨 2. 최신 코드로 NotchPlay를 빌드합니다..."
./build.sh

# 4. 앱 압축 (.app -> .zip)
echo "🗜️ 3. 빌드된 앱을 압축합니다..."
ZIP_NAME="NotchPlay_${TAG_VERSION}.zip"
# 이전 압축 파일이 있다면 삭제
rm -f NotchPlay_v*.zip
# 빌드된 앱을 압축
cd /Applications && zip -r -q "$ZIP_NAME" NotchPlay.app
mv "$ZIP_NAME" /Users/hyeonm9/.gemini/antigravity/scratch/NotchPlay/
cd /Users/hyeonm9/.gemini/antigravity/scratch/NotchPlay

# 5. GitHub Release 생성 및 업로드
echo "☁️ 4. GitHub Releases에 업로드 중..."
gh release create "$TAG_VERSION" "$ZIP_NAME" -t "NotchPlay Release $TAG_VERSION" -n "자동 빌드 및 배포된 버전입니다. ($CURRENT_TIME)"

echo "✅ 모든 프로세스가 성공적으로 완료되었습니다! ($TAG_VERSION)"
