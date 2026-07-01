#!/bin/bash
set -e

echo "Changing directory to apps/mobile..."
cd apps/mobile

echo "Cleaning previous build..."
flutter clean

echo "Loading environment variables from .env..."
ENV_FILE="../../.env"
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: .env file not found at $ENV_FILE"
    exit 1
fi

SUPABASE_URL=$(grep '^SUPABASE_URL=' "$ENV_FILE" | cut -d '=' -f2-)
SUPABASE_ANON_KEY=$(grep '^SUPABASE_ANON_KEY=' "$ENV_FILE" | cut -d '=' -f2-)
GOOGLE_ANDROID_CLIENT_ID=$(grep '^GOOGLE_ANDROID_CLIENT_ID=' "$ENV_FILE" | cut -d '=' -f2-)

echo "Building Local Release APK (AOT Compiled, Small Size)..."
flutter build apk --release \
  --dart-define="SUPABASE_URL=$SUPABASE_URL" \
  --dart-define="SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY" \
  --dart-define="GOOGLE_ANDROID_CLIENT_ID=$GOOGLE_ANDROID_CLIENT_ID"

echo "Build complete! The Local Release APK is located at apps/mobile/build/app/outputs/flutter-apk/app-release.apk"
