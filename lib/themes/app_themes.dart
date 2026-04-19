import 'package:flutter/material.dart';

class GameTheme {
  final String name;
  final String emoji;
  final Color background;
  final Color gridLine;
  final Color cellBg;
  final Color arrowColor;
  final Color arrowBorder;
  final Color freedColor;
  final Color blockedColor;
  final Color uiAccent;
  final Color textPrimary;
  final Color textSecondary;

  const GameTheme({
    required this.name,
    required this.emoji,
    required this.background,
    required this.gridLine,
    required this.cellBg,
    required this.arrowColor,
    required this.arrowBorder,
    required this.freedColor,
    required this.blockedColor,
    required this.uiAccent,
    required this.textPrimary,
    required this.textSecondary,
  });
}

class AppThemes {
  static const List<GameTheme> all = [
    GameTheme(
      name: 'Chalk',
      emoji: '🖊️',
      background: Color(0xFF1A1F2E),
      gridLine: Color(0xFF2E3550),
      cellBg: Color(0xFF222840),
      arrowColor: Color(0xFFE8E0D0),
      arrowBorder: Color(0xFFC8BFA8),
      freedColor: Color(0xFF7BE8A0),
      blockedColor: Color(0xFFFF5E6C),
      uiAccent: Color(0xFF6EC6FF),
      textPrimary: Color(0xFFE8E0D0),
      textSecondary: Color(0xFF8896B0),
    ),
    GameTheme(
      name: 'Neon',
      emoji: '⚡',
      background: Color(0xFF050510),
      gridLine: Color(0xFF0D1030),
      cellBg: Color(0xFF080820),
      arrowColor: Color(0xFF00FFCC),
      arrowBorder: Color(0xFF00CCAA),
      freedColor: Color(0xFFFFD700),
      blockedColor: Color(0xFFFF0066),
      uiAccent: Color(0xFF00FFCC),
      textPrimary: Color(0xFFFFFFFF),
      textSecondary: Color(0xFF5566AA),
    ),
    GameTheme(
      name: 'Paper',
      emoji: '📄',
      background: Color(0xFFF5F0E8),
      gridLine: Color(0xFFD8CFBE),
      cellBg: Color(0xFFEDE8DE),
      arrowColor: Color(0xFF3D3028),
      arrowBorder: Color(0xFF6B5A48),
      freedColor: Color(0xFF4A9E6B),
      blockedColor: Color(0xFFCC4040),
      uiAccent: Color(0xFF8B5A2B),
      textPrimary: Color(0xFF2A2018),
      textSecondary: Color(0xFF8B7860),
    ),
    GameTheme(
      name: 'Candy',
      emoji: '🍬',
      background: Color(0xFFFFEEF5),
      gridLine: Color(0xFFFFCCDD),
      cellBg: Color(0xFFFFF5F8),
      arrowColor: Color(0xFFD0408A),
      arrowBorder: Color(0xFFAA2068),
      freedColor: Color(0xFF40B060),
      blockedColor: Color(0xFFFF3040),
      uiAccent: Color(0xFFD0408A),
      textPrimary: Color(0xFF3A1028),
      textSecondary: Color(0xFFAA7090),
    ),
    GameTheme(
      name: 'Void',
      emoji: '🌑',
      background: Color(0xFF000000),
      gridLine: Color(0xFF111111),
      cellBg: Color(0xFF080808),
      arrowColor: Color(0xFFCCCCCC),
      arrowBorder: Color(0xFF888888),
      freedColor: Color(0xFF00FF88),
      blockedColor: Color(0xFFFF4444),
      uiAccent: Color(0xFFFFFFFF),
      textPrimary: Color(0xFFFFFFFF),
      textSecondary: Color(0xFF555555),
    ),
  ];

  static GameTheme forLevel(int level) => all[(level - 1) % all.length];
}
