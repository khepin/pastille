app := "Pastille"
build_dir := env("HOME") / "Library/Developer/Xcode/DerivedData/Pastille-gjinejnwyxzexhbwlzoolwrvllnc/Build/Products/Debug"

build:
    xcodebuild build -project Pastille.xcodeproj -scheme Pastille -configuration Debug -destination "platform=macOS"

run: build
    -killall "{{app}}" 2>/dev/null
    open "{{build_dir}}/{{app}}.app"
