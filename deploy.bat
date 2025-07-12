@echo off
echo "Cleaning previous build..."
flutter clean

echo "Getting dependencies..."
flutter pub get

echo "Building optimized Flutter web..."
flutter build web --web-renderer html --base-href "/nobat-dehi/" --release --tree-shake-icons

echo "Copying files to root..."
xcopy "build\web\*" "." /E /Y /Q

echo "Committing to Git..."
git add .
git commit -m "Update website - %date% %time%"

echo "Pushing to GitHub..."
git push origin main

echo "Deployment complete! Site will update in 2-3 minutes."
echo "URL: https://haman13.github.io/nobat-dehi/"
echo "Size optimized: HTML renderer used instead of CanvasKit"
pause 