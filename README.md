# 🌀 Arrow Jam v2.0 — Flutter Maze Game

A fully-featured, adaptive maze puzzle game with multiple user-selectable themes, adaptive difficulty, and sound support.

---

## ✨ What's New in v2.0

| Feature | Details |
|---|---|
| **7 Visual Themes** | Neon City, Lava Core, Deep Forest, Arctic Ice, Retro Arcade, Sakura Dream, Midnight |
| **Adaptive Difficulty** | Maze size & timer adjust based on your last 3 solve speeds |
| **Difficulty Label** | Shows 😴 Easy / ⚡ Normal / 🔥 Hard based on your pace |
| **Sound Effects** | Move, wall bump, win, lose — toggle in Settings or Home screen |
| **Background Music** | Looping ambient music — toggle anytime |
| **D-Pad + Swipe** | Both on-screen buttons AND swipe gesture input |
| **Settings Screen** | Audio toggles + full how-to-play guide |
| **Score + High Score** | Tracked across sessions |
| **Glow Effects** | Dynamic glow/pulse on dark themes |

---

## 🗂 Project Structure

```
lib/
├── main.dart
├── models/
│   ├── maze_model.dart       # Recursive backtracker maze generator
│   └── game_state.dart       # Adaptive difficulty engine + game logic
├── screens/
│   ├── home_screen.dart      # Theme picker, audio toggles, start
│   ├── game_screen.dart      # Gameplay: maze, HUD, D-pad, overlays
│   └── settings_screen.dart  # Audio settings + how-to-play
├── services/
│   └── audio_service.dart    # Music + SFX with toggle support
├── themes/
│   └── game_themes.dart      # 7 theme definitions
└── widgets/
    └── maze_painter.dart     # CustomPainter with glow effects
```

---

## 🔊 Adding Sound Assets

Create an `assets/sounds/` folder and add:

| File | Purpose |
|---|---|
| `move.mp3` | Player moves |
| `wall.mp3` | Bump into wall |
| `win.mp3` | Level complete |
| `lose.mp3` | Game over |
| `bg_music.mp3` | Looping background music |

The game runs silently without these files — no crash.

---

## 🛠 Setup

```bash
flutter pub get
flutter run
```

### Build APK
```bash
flutter build apk --release
```

---

## ⚙️ How Adaptive Difficulty Works

Every time you complete a level, the engine records your solve time as a ratio of the available time:

- **Solved in < 30% of time** → difficulty multiplier increases (+0.15), maze grows bigger, timer shrinks
- **Solved in > 75% of time** → difficulty multiplier decreases (-0.10), maze gets smaller, timer grows  
- **Between 30–75%** → difficulty stays the same

The multiplier is averaged over your last **3 levels** to smooth out lucky/unlucky runs.

---

## Dependencies

```yaml
google_fonts: ^6.1.0
provider: ^6.1.1
audioplayers: ^5.2.1
shared_preferences: ^2.2.2
```
