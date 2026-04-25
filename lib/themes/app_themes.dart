import 'package:flutter/material.dart';

class ThemeIcons {
  final String up, down, left, right;
  const ThemeIcons({required this.up, required this.down, required this.left, required this.right});
  String forDirection(ArrowDirection dir) => switch (dir) {
    ArrowDirection.up    => up,
    ArrowDirection.down  => down,
    ArrowDirection.left  => left,
    ArrowDirection.right => right,
  };
}

class AppTheme {
  final String id, name, emoji;
  final Color background, gridLine;
  final Color arrowUp, arrowDown, arrowLeft, arrowRight;
  final Color accent, textPrimary, textSecondary, cardBg, lifeActive;
  final bool isDark;
  final List<Color> bgGradient;
  final ThemeIcons? themeIcons;
  final int coinCost; // 0 = free

  const AppTheme({
    required this.id, required this.name, required this.emoji,
    required this.background, required this.gridLine,
    required this.arrowUp, required this.arrowDown,
    required this.arrowLeft, required this.arrowRight,
    required this.accent, required this.textPrimary,
    required this.textSecondary, required this.cardBg,
    required this.lifeActive, required this.isDark,
    required this.bgGradient,
    this.themeIcons,
    this.coinCost = 0,
  });

  Color arrowColor(ArrowDirection dir) => switch (dir) {
    ArrowDirection.up    => arrowUp,
    ArrowDirection.down  => arrowDown,
    ArrowDirection.left  => arrowLeft,
    ArrowDirection.right => arrowRight,
  };
}

enum ArrowDirection { up, down, left, right }

class AppThemes {
  static const List<AppTheme> all = [
    // ── FREE THEMES ──────────────────────────────────────────────────────────
    AppTheme(
      id: 'neon', name: 'Neon', emoji: '⚡', coinCost: 0,
      background: Color(0xFF070714), gridLine: Color(0xFF1A1A3A),
      arrowUp: Color(0xFF00FFCC), arrowDown: Color(0xFFFF3CAC),
      arrowLeft: Color(0xFF784BA0), arrowRight: Color(0xFF2B86C5),
      accent: Color(0xFF00FFCC), textPrimary: Color(0xFFEEEEFF),
      textSecondary: Color(0xFF666699), cardBg: Color(0xFF0F0F2A),
      lifeActive: Color(0xFFFF3CAC), isDark: true,
      bgGradient: [Color(0xFF070714), Color(0xFF0D0D28)],
    ),
    AppTheme(
      id: 'lava', name: 'Lava', emoji: '🌋', coinCost: 0,
      background: Color(0xFF110500), gridLine: Color(0xFF2A0A00),
      arrowUp: Color(0xFFFF6B00), arrowDown: Color(0xFFFFD000),
      arrowLeft: Color(0xFFFF3000), arrowRight: Color(0xFFFF8C00),
      accent: Color(0xFFFF6B00), textPrimary: Color(0xFFFFEDCC),
      textSecondary: Color(0xFF884400), cardBg: Color(0xFF1A0800),
      lifeActive: Color(0xFFFF3000), isDark: true,
      bgGradient: [Color(0xFF110500), Color(0xFF200800)],
      themeIcons: ThemeIcons(up: '🔥', down: '💥', left: '🌋', right: '☄️'),
    ),
    AppTheme(
      id: 'arctic', name: 'Arctic', emoji: '❄️', coinCost: 0,
      background: Color(0xFFEDF4FB), gridLine: Color(0xFFCCDDEE),
      arrowUp: Color(0xFF0055CC), arrowDown: Color(0xFF0099DD),
      arrowLeft: Color(0xFF5500CC), arrowRight: Color(0xFF00AACC),
      accent: Color(0xFF0055CC), textPrimary: Color(0xFF102040),
      textSecondary: Color(0xFF6688AA), cardBg: Color(0xFFDDEEF8),
      lifeActive: Color(0xFF0055CC), isDark: false,
      bgGradient: [Color(0xFFEDF4FB), Color(0xFFD8EEF8)],
      themeIcons: ThemeIcons(up: '🐧', down: '❄️', left: '🦭', right: '🐋'),
    ),

    // ── PAID THEMES ───────────────────────────────────────────────────────────
    AppTheme(
      id: 'forest', name: 'Forest', emoji: '🌿', coinCost: 15,
      background: Color(0xFF060E06), gridLine: Color(0xFF0F200F),
      arrowUp: Color(0xFF44FF88), arrowDown: Color(0xFFAAFF44),
      arrowLeft: Color(0xFF00CC66), arrowRight: Color(0xFF66FF00),
      accent: Color(0xFF44FF88), textPrimary: Color(0xFFDDFFDD),
      textSecondary: Color(0xFF336633), cardBg: Color(0xFF0A180A),
      lifeActive: Color(0xFF44FF88), isDark: true,
      bgGradient: [Color(0xFF060E06), Color(0xFF0A160A)],
      themeIcons: ThemeIcons(up: '🦅', down: '🐸', left: '🐺', right: '🦊'),
    ),
    AppTheme(
      id: 'retro', name: 'Retro', emoji: '🕹️', coinCost: 15,
      background: Color(0xFF1A1A1A), gridLine: Color(0xFF2A2A2A),
      arrowUp: Color(0xFFFFFF00), arrowDown: Color(0xFFFF4444),
      arrowLeft: Color(0xFF44FFFF), arrowRight: Color(0xFF44FF44),
      accent: Color(0xFFFFFF00), textPrimary: Color(0xFFFFFFFF),
      textSecondary: Color(0xFF666666), cardBg: Color(0xFF252525),
      lifeActive: Color(0xFFFF4444), isDark: true,
      bgGradient: [Color(0xFF1A1A1A), Color(0xFF222222)],
      themeIcons: ThemeIcons(up: '👾', down: '🕹️', left: '👈', right: '👉'),
    ),
    AppTheme(
      id: 'sakura', name: 'Sakura', emoji: '🌸', coinCost: 20,
      background: Color(0xFFFFF5F8), gridLine: Color(0xFFFFDDE8),
      arrowUp: Color(0xFFDD1166), arrowDown: Color(0xFFFF6699),
      arrowLeft: Color(0xFF990044), arrowRight: Color(0xFFFF44AA),
      accent: Color(0xFFDD1166), textPrimary: Color(0xFF440022),
      textSecondary: Color(0xFFBB6688), cardBg: Color(0xFFFFEEF4),
      lifeActive: Color(0xFFDD1166), isDark: false,
      bgGradient: [Color(0xFFFFF5F8), Color(0xFFFFEEF4)],
      themeIcons: ThemeIcons(up: '🌸', down: '🌺', left: '🦋', right: '🌷'),
    ),
    AppTheme(
      id: 'traffic', name: 'Traffic', emoji: '🚦', coinCost: 20,
      background: Color(0xFF111820), gridLine: Color(0xFF1E2D3D),
      arrowUp: Color(0xFF00CC55), arrowDown: Color(0xFFFF3333),
      arrowLeft: Color(0xFFFFAA00), arrowRight: Color(0xFF3399FF),
      accent: Color(0xFF00CC55), textPrimary: Color(0xFFE8F4FF),
      textSecondary: Color(0xFF4A6480), cardBg: Color(0xFF182030),
      lifeActive: Color(0xFFFF3333), isDark: true,
      bgGradient: [Color(0xFF111820), Color(0xFF182030)],
      themeIcons: ThemeIcons(up: '🚗', down: '🚕', left: '🚙', right: '🚌'),
    ),
    AppTheme(
      id: 'space', name: 'Space', emoji: '🚀', coinCost: 25,
      background: Color(0xFF020408), gridLine: Color(0xFF0A1020),
      arrowUp: Color(0xFFAADDFF), arrowDown: Color(0xFFFF66AA),
      arrowLeft: Color(0xFF8855FF), arrowRight: Color(0xFFFFDD44),
      accent: Color(0xFFAADDFF), textPrimary: Color(0xFFDDEEFF),
      textSecondary: Color(0xFF334466), cardBg: Color(0xFF050C18),
      lifeActive: Color(0xFFFF66AA), isDark: true,
      bgGradient: [Color(0xFF020408), Color(0xFF050C18)],
      themeIcons: ThemeIcons(up: '🚀', down: '🛸', left: '🛩️', right: '☄️'),
    ),
    AppTheme(
      id: 'ocean', name: 'Ocean', emoji: '🌊', coinCost: 20,
      background: Color(0xFF020D1A), gridLine: Color(0xFF0A2030),
      arrowUp: Color(0xFF00AAFF), arrowDown: Color(0xFF00FFDD),
      arrowLeft: Color(0xFF0055FF), arrowRight: Color(0xFF44DDFF),
      accent: Color(0xFF00AAFF), textPrimary: Color(0xFFCCEEFF),
      textSecondary: Color(0xFF336688), cardBg: Color(0xFF051525),
      lifeActive: Color(0xFF00FFDD), isDark: true,
      bgGradient: [Color(0xFF020D1A), Color(0xFF051525)],
      themeIcons: ThemeIcons(up: '🐬', down: '🐙', left: '🦈', right: '🐠'),
    ),
    AppTheme(
      id: 'desert', name: 'Desert', emoji: '🏜️', coinCost: 15,
      background: Color(0xFF1A1000), gridLine: Color(0xFF2A1E00),
      arrowUp: Color(0xFFFFCC44), arrowDown: Color(0xFFFF8800),
      arrowLeft: Color(0xFFDD6600), arrowRight: Color(0xFFFFAA22),
      accent: Color(0xFFFFCC44), textPrimary: Color(0xFFFFF0CC),
      textSecondary: Color(0xFF885500), cardBg: Color(0xFF221500),
      lifeActive: Color(0xFFFF8800), isDark: true,
      bgGradient: [Color(0xFF1A1000), Color(0xFF221500)],
      themeIcons: ThemeIcons(up: '🦅', down: '🦂', left: '🐫', right: '🌵'),
    ),
    AppTheme(
      id: 'candy', name: 'Candy', emoji: '🍬', coinCost: 20,
      background: Color(0xFFFFF0F8), gridLine: Color(0xFFFFCCEE),
      arrowUp: Color(0xFFFF44AA), arrowDown: Color(0xFF44AAFF),
      arrowLeft: Color(0xFFFF9900), arrowRight: Color(0xFF44FF88),
      accent: Color(0xFFFF44AA), textPrimary: Color(0xFF330022),
      textSecondary: Color(0xFFAA6688), cardBg: Color(0xFFFFDDF5),
      lifeActive: Color(0xFFFF44AA), isDark: false,
      bgGradient: [Color(0xFFFFF0F8), Color(0xFFFFDDF5)],
      themeIcons: ThemeIcons(up: '🍭', down: '🍬', left: '🍩', right: '🎂'),
    ),
    AppTheme(
      id: 'midnight', name: 'Midnight', emoji: '🌙', coinCost: 25,
      background: Color(0xFF05050F), gridLine: Color(0xFF10101E),
      arrowUp: Color(0xFF8866FF), arrowDown: Color(0xFF4488FF),
      arrowLeft: Color(0xFFAA44FF), arrowRight: Color(0xFF44CCFF),
      accent: Color(0xFF8866FF), textPrimary: Color(0xFFDDCCFF),
      textSecondary: Color(0xFF442266), cardBg: Color(0xFF0A0A1A),
      lifeActive: Color(0xFF8866FF), isDark: true,
      bgGradient: [Color(0xFF05050F), Color(0xFF0A0A1A)],
      themeIcons: ThemeIcons(up: '🌙', down: '⭐', left: '🦉', right: '🌟'),
    ),
    AppTheme(
      id: 'volcano', name: 'Volcano', emoji: '🌋', coinCost: 30,
      background: Color(0xFF0A0000), gridLine: Color(0xFF1A0500),
      arrowUp: Color(0xFFFF2200), arrowDown: Color(0xFFFF6600),
      arrowLeft: Color(0xFFCC0000), arrowRight: Color(0xFFFFAA00),
      accent: Color(0xFFFF2200), textPrimary: Color(0xFFFFCCBB),
      textSecondary: Color(0xFF660000), cardBg: Color(0xFF150000),
      lifeActive: Color(0xFFFF2200), isDark: true,
      bgGradient: [Color(0xFF0A0000), Color(0xFF150000)],
      themeIcons: ThemeIcons(up: '🌋', down: '💀', left: '🔥', right: '☄️'),
    ),
    AppTheme(
      id: 'matrix', name: 'Matrix', emoji: '💻', coinCost: 30,
      background: Color(0xFF000800), gridLine: Color(0xFF001200),
      arrowUp: Color(0xFF00FF44), arrowDown: Color(0xFF00CC33),
      arrowLeft: Color(0xFF008800), arrowRight: Color(0xFF44FF88),
      accent: Color(0xFF00FF44), textPrimary: Color(0xFFCCFFCC),
      textSecondary: Color(0xFF226622), cardBg: Color(0xFF001000),
      lifeActive: Color(0xFF00FF44), isDark: true,
      bgGradient: [Color(0xFF000800), Color(0xFF001000)],
      themeIcons: ThemeIcons(up: '💻', down: '⌨️', left: '🖥️', right: '📡'),
    ),
  ];

  static AppTheme byId(String id) =>
      all.firstWhere((t) => t.id == id, orElse: () => all[0]);
}
