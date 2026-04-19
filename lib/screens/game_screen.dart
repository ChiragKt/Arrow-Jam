import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/settings_state.dart';
import '../themes/app_themes.dart';
import '../widgets/arrow_grid.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsState>();
    final theme = AppThemes.byId(settings.themeId);
    final gs = context.watch<GameState>();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: theme.bgGradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _TopBar(theme: theme, gs: gs),
                  Expanded(
                    child: Center(
                      child: _MazeArea(theme: theme, gs: gs),
                    ),
                  ),
                  _BottomBar(theme: theme, gs: gs),
                ],
              ),
              if (gs.levelWon)
                _Overlay(
                  theme: theme,
                  won: true,
                  gs: gs,
                  onAction: () {
                    gs.nextLevel();
                  },
                  onQuit: () => Navigator.pop(context),
                ),
              if (gs.gameOver)
                _Overlay(
                  theme: theme,
                  won: false,
                  gs: gs,
                  onAction: () => gs.startGame(),
                  onQuit: () => Navigator.pop(context),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final AppTheme theme;
  final GameState gs;
  const _TopBar({required this.theme, required this.gs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          // Back
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(Icons.close, color: theme.textSecondary, size: 22),
          ),
          const Spacer(),
          // Level
          Text(
            'LVL ${gs.level}',
            style: GoogleFonts.spaceMono(
              color: theme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          // Score
          Text(
            '${gs.score}',
            style: GoogleFonts.spaceMono(
              color: theme.accent,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MazeArea extends StatelessWidget {
  final AppTheme theme;
  final GameState gs;
  const _MazeArea({required this.theme, required this.gs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: theme.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.gridLine,
            width: 1.5,
          ),
          boxShadow: theme.isDark
              ? [
                  BoxShadow(
                    color: theme.accent.withValues(alpha: 0.12),
                    blurRadius: 24,
                    spreadRadius: 2,
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                  )
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: ArrowGrid(
            gs: gs,
            theme: theme,
            onTap: (_) {},
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final AppTheme theme;
  final GameState gs;
  const _BottomBar({required this.theme, required this.gs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (i) {
          final alive = i < gs.lives;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: alive
                    ? theme.lifeActive
                    : theme.textSecondary.withValues(alpha: 0.15),
                boxShadow: alive && theme.isDark
                    ? [BoxShadow(color: theme.lifeActive.withValues(alpha: 0.5), blurRadius: 8)]
                    : null,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _Overlay extends StatelessWidget {
  final AppTheme theme;
  final bool won;
  final GameState gs;
  final VoidCallback onAction;
  final VoidCallback onQuit;

  const _Overlay({
    required this.theme,
    required this.won,
    required this.gs,
    required this.onAction,
    required this.onQuit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 48),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: theme.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (won ? theme.accent : Colors.red).withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                won ? '✓' : '✕',
                style: TextStyle(
                  fontSize: 44,
                  color: won ? theme.accent : Colors.red,
                  fontWeight: FontWeight.w100,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                won ? 'CLEARED' : 'GAME OVER',
                style: GoogleFonts.spaceMono(
                  color: won ? theme.accent : Colors.red,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Score: ${gs.score}',
                style: GoogleFonts.spaceMono(
                  color: theme.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),
              _Btn(
                label: won ? 'NEXT LEVEL' : 'TRY AGAIN',
                color: theme.accent,
                textDark: !theme.isDark,
                onTap: onAction,
                theme: theme,
              ),
              const SizedBox(height: 10),
              _Btn(
                label: 'QUIT',
                color: Colors.transparent,
                textDark: false,
                onTap: onQuit,
                theme: theme,
                outlined: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final String label;
  final Color color;
  final bool textDark;
  final bool outlined;
  final VoidCallback onTap;
  final AppTheme theme;

  const _Btn({
    required this.label,
    required this.color,
    required this.textDark,
    required this.onTap,
    required this.theme,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: outlined
          ? OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: theme.textSecondary.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: onTap,
              child: Text(
                label,
                style: GoogleFonts.spaceMono(
                  color: theme.textSecondary,
                  fontSize: 12,
                  letterSpacing: 2,
                ),
              ),
            )
          : ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: textDark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              onPressed: onTap,
              child: Text(
                label,
                style: GoogleFonts.spaceMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ),
    );
  }
}
