import 'package:flutter/material.dart';

class AppTheme {
  final String id;
  final String name;
  final String emoji;
  final Color background;
  final Color gridLine;
  final Color arrowUp;
  final Color arrowDown;
  final Color arrowLeft;
  final Color arrowRight;
  final Color accent;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardBg;
  final Color lifeActive;
  final bool isDark;
  final List<Color> bgGradient;

  const AppTheme({
    required this.id,
    required this.name,
    required this.emoji,
    required this.background,
    required this.gridLine,
    required this.arrowUp,
    required this.arrowDown,
    required this.arrowLeft,
    required this.arrowRight,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardBg,
    required this.lifeActive,
    required this.isDark,
    required this.bgGradient,
  });

  Color arrowColor(ArrowDirection dir) {
    switch (dir) {
      case ArrowDirection.up: return arrowUp;
      case ArrowDirection.down: return arrowDown;
      case ArrowDirection.left: return arrowLeft;
      case ArrowDirection.right: return arrowRight;
    }
  }
}

enum ArrowDirection { up, down, left, right }

class AppThemes {
  static const List<AppTheme> all = [
    AppTheme(
      id: 'neon',
      name: 'Neon',
      emoji: '⚡',
      background: Color(0xFF070714),
      gridLine: Color(0xFF1A1A3A),
      arrowUp: Color(0xFF00FFCC),
      arrowDown: Color(0xFFFF3CAC),
      arrowLeft: Color(0xFF784BA0),
      arrowRight: Color(0xFF2B86C5),
      accent: Color(0xFF00FFCC),
      textPrimary: Color(0xFFEEEEFF),
      textSecondary: Color(0xFF666699),
      cardBg: Color(0xFF0F0F2A),
      lifeActive: Color(0xFFFF3CAC),
      isDark: true,
      bgGradient: [Color(0xFF070714), Color(0xFF0D0D28)],
    ),
    AppTheme(
      id: 'lava',
      name: 'Lava',
      emoji: '🌋',
      background: Color(0xFF110500),
      gridLine: Color(0xFF2A0A00),
      arrowUp: Color(0xFFFF6B00),
      arrowDown: Color(0xFFFFD000),
      arrowLeft: Color(0xFFFF3000),
      arrowRight: Color(0xFFFF8C00),
      accent: Color(0xFFFF6B00),
      textPrimary: Color(0xFFFFEDCC),
      textSecondary: Color(0xFF884400),
      cardBg: Color(0xFF1A0800),
      lifeActive: Color(0xFFFF3000),
      isDark: true,
      bgGradient: [Color(0xFF110500), Color(0xFF200800)],
    ),
    AppTheme(
      id: 'arctic',
      name: 'Arctic',
      emoji: '❄️',
      background: Color(0xFFEDF4FB),
      gridLine: Color(0xFFCCDDEE),
      arrowUp: Color(0xFF0055CC),
      arrowDown: Color(0xFF0099DD),
      arrowLeft: Color(0xFF5500CC),
      arrowRight: Color(0xFF00AACC),
      accent: Color(0xFF0055CC),
      textPrimary: Color(0xFF102040),
      textSecondary: Color(0xFF6688AA),
      cardBg: Color(0xFFDDEEF8),
      lifeActive: Color(0xFF0055CC),
      isDark: false,
      bgGradient: [Color(0xFFEDF4FB), Color(0xFFD8EEF8)],
    ),
    AppTheme(
      id: 'forest',
      name: 'Forest',
      emoji: '🌿',
      background: Color(0xFF060E06),
      gridLine: Color(0xFF0F200F),
      arrowUp: Color(0xFF44FF88),
      arrowDown: Color(0xFFAAFF44),
      arrowLeft: Color(0xFF00CC66),
      arrowRight: Color(0xFF66FF00),
      accent: Color(0xFF44FF88),
      textPrimary: Color(0xFFDDFFDD),
      textSecondary: Color(0xFF336633),
      cardBg: Color(0xFF0A180A),
      lifeActive: Color(0xFF44FF88),
      isDark: true,
      bgGradient: [Color(0xFF060E06), Color(0xFF0A160A)],
    ),
    AppTheme(
      id: 'retro',
      name: 'Retro',
      emoji: '🕹️',
      background: Color(0xFF1A1A1A),
      gridLine: Color(0xFF2A2A2A),
      arrowUp: Color(0xFFFFFF00),
      arrowDown: Color(0xFFFF4444),
      arrowLeft: Color(0xFF44FFFF),
      arrowRight: Color(0xFF44FF44),
      accent: Color(0xFFFFFF00),
      textPrimary: Color(0xFFFFFFFF),
      textSecondary: Color(0xFF666666),
      cardBg: Color(0xFF252525),
      lifeActive: Color(0xFFFF4444),
      isDark: true,
      bgGradient: [Color(0xFF1A1A1A), Color(0xFF222222)],
    ),
    AppTheme(
      id: 'sakura',
      name: 'Sakura',
      emoji: '🌸',
      background: Color(0xFFFFF5F8),
      gridLine: Color(0xFFFFDDE8),
      arrowUp: Color(0xFFDD1166),
      arrowDown: Color(0xFFFF6699),
      arrowLeft: Color(0xFF990044),
      arrowRight: Color(0xFFFF44AA),
      accent: Color(0xFFDD1166),
      textPrimary: Color(0xFF440022),
      textSecondary: Color(0xFFBB6688),
      cardBg: Color(0xFFFFEEF4),
      lifeActive: Color(0xFFDD1166),
      isDark: false,
      bgGradient: [Color(0xFFFFF5F8), Color(0xFFFFEEF4)],
    ),
  ];

  static AppTheme byId(String id) =>
      all.firstWhere((t) => t.id == id, orElse: () => all[0]);
}
