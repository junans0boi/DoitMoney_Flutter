#!/bin/bash

AVD_NAME="Medium_Phone_API_36.0"

echo "🚀 Android Emulator 실행 중 ($AVD_NAME)..."
nohup ~/Library/Android/sdk/emulator/emulator -avd "$AVD_NAME" > /dev/null 2>&1 &

echo "⏳ Android emulator를 부팅 중이니 기다리세요..."
adb wait-for-device

# gradlew는 android 디렉토리에서 실행해야 함
echo "🧹 android/ 디렉토리에서 gradlew clean 실행 중..."
cd android
./gradlew clean
cd ..

# Flutter 루트에 있으므로 여기서 실행
echo "🧼 플러터를 초기화 합니다...."
flutter clean

echo "📦 플러터 패키지를 불러오고 있습니다..."
flutter pub get

echo "🚀 플러터 앱을 emulator-5554에 실행시킵니다..."
flutter run -d emulator-5554
