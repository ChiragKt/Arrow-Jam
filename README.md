# 🌀 Arrow Jam — Flutter Game

A fully-featured maze puzzle game inspired by swipe-navigation mechanics, built in Flutter.

## Features
- ✅ **Randomly generated mazes** using recursive backtracker algorithm
- ✅ **Swipe/drag** navigation through the maze
- ✅ **5 progressively harder levels** (maze grows each level)
- ✅ **Countdown timer** per level (lose a life if time runs out)
- ✅ **3 lives system** with heart UI
- ✅ **5 visual themes**: Classic, Neon, Forest, Lava, Ice
- ✅ **Theme changes** every level automatically
- ✅ **Zoom in/out** via pinch gesture (InteractiveViewer)
- ✅ **Hint system** — shows direction of goal
- ✅ **Reset** — restart current level from start
- ✅ Home screen with theme picker

## Project Structure
```
lib/
├── main.dart                  # App entry point
├── models/
│   ├── maze_model.dart        # Maze generation (recursive backtracker)
│   └── game_state.dart        # Game state (lives, timer, level)
├── screens/
│   ├── home_screen.dart       # Main menu with theme picker
│   └── game_screen.dart       # Core gameplay screen
├── widgets/
│   └── maze_painter.dart      # Custom canvas painter for maze
└── themes/
    └── game_themes.dart       # 5 color themes
```

## Setup

### Prerequisites
- Flutter SDK >= 3.0.0
- Dart >= 3.0.0

### Install & Run
```bash
# 1. Clone / copy this project into a folder
cd arrow_jam

# 2. Get dependencies
flutter pub get

# 3. Run on device/emulator
flutter run
```

### Build APK (Android)
```bash
flutter build apk --release
```

### Build for iOS
```bash
flutter build ios --release
```

## How to Play
1. Launch the app and select a theme
2. Tap **Start Game**
3. **Swipe your finger** in any direction to move the blue dot through the maze
4. Reach the **green goal** before time runs out
5. Complete all 5 levels to win!

## Customization
- Add more levels: edit `mazeSizeForLevel` and `timeLimitForLevel` in `game_state.dart`
- Add themes: append to `GameThemes.themes` list in `game_themes.dart`
- Change maze algorithm: replace `_carve()` in `maze_model.dart`

## Dependencies
```yaml
google_fonts: ^6.1.0
```
