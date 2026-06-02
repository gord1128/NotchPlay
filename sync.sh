#!/bin/bash

# NotchPlay GitHub Auto-Sync Script
# 이 스크립트를 실행하면 현재 변경된 내용이 현재 시간과 함께 GitHub에 자동 업로드됩니다.

echo "🚀 NotchPlay GitHub 동기화를 시작합니다..."

# 1. 변경된 모든 파일 추가
git add .

# 2. 커밋 메시지에 현재 시간 추가
CURRENT_TIME=$(date "+%Y-%m-%d %H:%M:%S")
git commit -m "♻️ Auto-sync: $CURRENT_TIME"

# 3. GitHub로 푸시
echo "☁️ GitHub로 코드를 안전하게 업로드하는 중..."
git push origin main

echo "✅ 모든 코드가 성공적으로 백업되었습니다!"
