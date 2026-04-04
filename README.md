# Pastille

A lightweight macOS clipboard manager that lives in your menu bar.

## Features

- Infinite clipboard history with configurable limit
- Bottom-of-screen panel with tile previews
- Shows source app icon and name for each entry
- Search and filter history
- Keyboard-driven navigation (arrows, Enter to paste, Escape to dismiss)
- Shift+Enter pastes as plain text (strips formatting)
- Global hotkey: Cmd+Shift+V (customizable)
- App exclusion list (password managers auto-detected via concealed clipboard markers)
- Launch at login

## Requirements

- macOS 14 (Sonoma) or later
- Accessibility permission (for paste simulation)

## Building

```
brew install xcodegen
xcodegen generate
open Pastille.xcodeproj
```

Build and run from Xcode (Cmd+R).

## License

[MIT](LICENSE.md)
