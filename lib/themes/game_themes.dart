import 'package:flutter/material.dart';

class GameTheme {
  final String id;
  final String name;
  final String emoji;
  final Color background;
  final Color wallColor;
  final Color playerColor;
  final Color goalColor;
  final Color pathColor;
  final Color uiAccent;
  final Color uiText;
  final Color cardBackground;
  final List<Color> gradientColors;
  final bool isDark;

  const GameTheme({
    required this.id,
    required this.name,
    required this.emoji,
    required this.background,
    required this.wallColor,
    required this.playerColor,
    required this.goalColor,
    required this.pathColor,
    required this.uiAccent,
    required this.uiText,
    required this.cardBackground,
    required this.gradientColors,
    required this.isDark,
  });
}

class GameThemes {
  static const List<GameTheme> all = [
    GameTheme(
      id: 'neon',
      name: 'Neon City',
      emoji: '🌆',
      background: Color(0xFF0A0A1A),
      wallColor: Color(0xFF00FFFF),
      playerColor: Color(0xFFFF00FF),
      goalColor: Color(0xFF00FF88),
      pathColor: Color(0xFF1A1A2E),
      uiAccent: Color(0xFF00FFFF),
      uiText: Color(0xFFE0E0FF),
      cardBackground: Color(0xFF12122A),
      gradientColors: [Color(0xFF0A0A1A), Color(0xFF1A0A2E)],
      isDark: true,
    ),
    GameTheme(
      id: 'lava',
      name: 'Lava Core',
      emoji: '🌋',
      background: Color(0xFF1A0500),
      wallColor: Color(0xFFFF4500),
      playerColor: Color(0xFFFFD700),
      goalColor: Color(0xFFFF8C00),
      pathColor: Color(0xFF2A0800),
      uiAccent: Color(0xFFFF4500),
      uiText: Color(0xFFFFE4B5),
      cardBackground: Color(0xFF220A00),
      gradientColors: [Color(0xFF1A0500), Color(0xFF3A0800)],
      isDark: true,
    ),
    GameTheme(
      id: 'forest',
      name: 'Deep Forest',
      emoji: '🌿',
      background: Color(0xFF0A1A0A),
      wallColor: Color(0xFF2ECC71),
      playerColor: Color(0xFF00FF7F),
      goalColor: Color(0xFFFFD700),
      pathColor: Color(0xFF0F2A0F),
      uiAccent: Color(0xFF2ECC71),
      uiText: Color(0xFFDCF5DC),
      cardBackground: Color(0xFF112211),
      gradientColors: [Color(0xFF0A1A0A), Color(0xFF0A2A10)],
      isDark: true,
    ),
    GameTheme(
      id: 'ice',
      name: 'Arctic Ice',
      emoji: '❄️',
      background: Color(0xFFF0F8FF),
      wallColor: Color(0xFF4A90D9),
      playerColor: Color(0xFF0055A4),
      goalColor: Color(0xFF00BCD4),
      pathColor: Color(0xFFE8F4FD),
      uiAccent: Color(0xFF4A90D9),
      uiText: Color(0xFF1A3A5C),
      cardBackground: Color(0xFFDCEEFA),
      gradientColors: [Color(0xFFF0F8FF), Color(0xFFD0EAFA)],
      isDark: false,
    ),
    GameTheme(
      id: 'retro',
      name: 'Retro Arcade',
      emoji: '🕹️',
      background: Color(0xFF1A1A1A),
      wallColor: Color(0xFFFFFF00),
      playerColor: Color(0xFFFF3C3C),
      goalColor: Color(0xFF00FF00),
      pathColor: Color(0xFF2A2A2A),
      uiAccent: Color(0xFFFFFF00),
      uiText: Color(0xFFFFFFFF),
      cardBackground: Color(0xFF252525),
      gradientColors: [Color(0xFF1A1A1A), Color(0xFF2A1A2A)],
      isDark: true,
    ),
    GameTheme(
      id: 'sakura',
      name: 'Sakura Dream',
      emoji: '🌸',
      background: Color(0xFFFFF0F5),
      wallColor: Color(0xFFFF69B4),
      playerColor: Color(0xFFDC143C),
      goalColor: Color(0xFFFF1493),
      pathColor: Color(0xFFFFF5F8),
      uiAccent: Color(0xFFFF69B4),
      uiText: Color(0xFF5C1A3A),
      cardBackground: Color(0xFFFFE4EF),
      gradientColors: [Color(0xFFFFF0F5), Color(0xFFFFD0E8)],
      isDark: false,
    ),
    GameTheme(
      id: 'midnight',
      name: 'Midnight',
      emoji: '🌙',
      background: Color(0xFF05050F),
      wallColor: Color(0xFF7B68EE),
      playerColor: Color(0xFFDDA0DD),
      goalColor: Color(0xFFADFF2F),
      pathColor: Color(0xFF0D0D20),
      uiAccent: Color(0xFF7B68EE),
      uiText: Color(0xFFE8E0FF),
      cardBackground: Color(0xFF0F0F25),
      gradientColors: [Color(0xFF05050F), Color(0xFF0F0520)],
      isDark: true,
    ),
  ];

  static GameTheme byId(String id) =>
      all.firstWhere((t) => t.id == id, orElse: () => all[0]);
}
