import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/settings_state.dart';
import '../themes/app_themes.dart';
import '../widgets/arrow_grid.dart';
import '../services/ad_service.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  Timer? _timer;

  // Track whether a rewarded ad is available so the button updates live
  bool _rewardedReady = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _pollRewardedReady();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final gs = context.read<GameState>();
      if (!gs.gameOver && !gs.levelWon) {
        gs.tick();
      }
      // Keep rewarded-ready flag in sync each tick
      final ready = AdService().rewardedReady;
      if (ready != _rewardedReady) {
        setState(() => _rewardedReady = ready);
      }
    });
  }

  // Poll once per second so the button appears as soon as the ad loads
  void _pollRewardedReady() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      final ready = AdService().rewardedReady;
      if (ready != _rewardedReady) {
        setState(() => _rewardedReady = ready);
      }
      return true; // keep polling
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsState>();
    final theme    = AppThemes.byId(settings.themeId);
    final gs       = context.watch<GameState>();

    if (gs.levelWon) _timer?.cancel();

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
                  _buildHUD(theme, gs),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.background,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: theme.gridLine, width: 1.5),
                            boxShadow: theme.isDark
                                ? [BoxShadow(
                                    color: theme.accent.withValues(alpha: 0.12),
                                    blurRadius: 24, spreadRadius: 2)]
                                : [BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 16)],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: ArrowGrid(gs: gs, theme: theme, onTap: (_) {}),
                          ),
                        ),
                      ),
                    ),
                  ),
                  _buildLivesBar(theme, gs),
                ],
              ),
              if (gs.levelWon)  _buildOverlay(theme, gs, won: true),
              if (gs.gameOver)  _buildOverlay(theme, gs, won: false),
            ],
          ),
        ),
      ),
    );
  }

  // ── HUD ───────────────────────────────────────────────────────────────────

  Widget _buildHUD(AppTheme theme, GameState gs) {
    final timeRatio  = gs.timeRemaining / gs.difficulty.timeSeconds;
    final timerColor = timeRatio > 0.5
        ? theme.accent
        : timeRatio > 0.25
            ? const Color(0xFFFFAA00)
            : Colors.red;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () { _timer?.cancel(); Navigator.pop(context); },
            child: Icon(Icons.close, color: theme.textSecondary, size: 22),
          ),
          const Spacer(),
          Text(
            'LVL ${gs.level}',
            style: GoogleFonts.spaceMono(
              color: theme.textPrimary, fontSize: 14,
              fontWeight: FontWeight.w700, letterSpacing: 2,
            ),
          ),
          const SizedBox(width: 20),
          _TimerBadge(seconds: gs.timeRemaining, color: timerColor, theme: theme),
          const Spacer(),
          Text(
            '${gs.score}',
            style: GoogleFonts.spaceMono(
              color: theme.accent, fontSize: 14, fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ── Lives bar ─────────────────────────────────────────────────────────────

  Widget _buildLivesBar(AppTheme theme, GameState gs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(gs.difficulty.lives, (i) {
          final alive = i < gs.lives;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: AnimatedScale(
              scale: alive ? 1.0 : 0.7,
              duration: const Duration(milliseconds: 300),
              child: Icon(
                alive ? Icons.favorite : Icons.favorite_border,
                color: alive
                    ? theme.lifeActive
                    : theme.textSecondary.withValues(alpha: 0.3),
                size: 26,
                shadows: alive && theme.isDark
                    ? [Shadow(color: theme.lifeActive.withValues(alpha: 0.6), blurRadius: 8)]
                    : null,
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Overlay (level won / game over) ───────────────────────────────────────

  Widget _buildOverlay(AppTheme theme, GameState gs, {required bool won}) {
    return Container(
      color: Colors.black.withValues(alpha: 0.72),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 44),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: theme.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (won ? theme.accent : Colors.red).withValues(alpha: 0.45),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                won ? '✓' : '✕',
                style: TextStyle(
                  fontSize: 48,
                  color: won ? theme.accent : Colors.red,
                  fontWeight: FontWeight.w100,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                won ? 'CLEARED' : 'GAME OVER',
                style: GoogleFonts.spaceMono(
                  color: won ? theme.accent : Colors.red,
                  fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Score: ${gs.score}',
                style: GoogleFonts.spaceMono(
                  color: theme.textSecondary, fontSize: 12,
                ),
              ),
              const SizedBox(height: 22),

              // ── Level won ───────────────────────────────────────────────
              if (won) ...[
                _overlayBtn(
                  label: 'NEXT LEVEL',
                  color: theme.accent,
                  textDark: !theme.isDark,
                  theme: theme,
                  onTap: () {
                    AdService().maybeShowInterstitial(gs.level);
                    gs.nextLevel();
                    _startTimer();
                  },
                ),
                const SizedBox(height: 10),
                _overlayBtn(
                  label: 'QUIT',
                  color: Colors.transparent,
                  textDark: false,
                  outlined: true,
                  theme: theme,
                  onTap: () => Navigator.pop(context),
                ),
              ],

              // ── Game over ───────────────────────────────────────────────
              if (!won) ...[
                // Watch ad → continue with 1 heart (only shown when ad is ready)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _rewardedReady
                      ? Column(
                          key: const ValueKey('adBtn'),
                          children: [
                            _overlayBtn(
                              label: '▶  CONTINUE  (AD)',
                              color: const Color(0xFFFFAA00),
                              textDark: true,
                              theme: theme,
                              onTap: () {
                                AdService().showRewarded(
                                  onRewarded: () {
                                    gs.continueAfterGameOver();
                                    setState(() => _rewardedReady = false);
                                    _startTimer();
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 10),
                          ],
                        )
                      : const SizedBox.shrink(key: ValueKey('noAdBtn')),
                ),
                _overlayBtn(
                  label: 'TRY AGAIN',
                  color: theme.accent,
                  textDark: !theme.isDark,
                  theme: theme,
                  onTap: () {
                    gs.resetGame();
                    _startTimer();
                  },
                ),
                const SizedBox(height: 10),
                _overlayBtn(
                  label: 'QUIT',
                  color: Colors.transparent,
                  textDark: false,
                  outlined: true,
                  theme: theme,
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Button helper ─────────────────────────────────────────────────────────

  Widget _overlayBtn({
    required String       label,
    required Color        color,
    required bool         textDark,
    required AppTheme     theme,
    required VoidCallback onTap,
    bool outlined = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: outlined
          ? OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: theme.textSecondary.withValues(alpha: 0.35)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: onTap,
              child: Text(label,
                  style: GoogleFonts.spaceMono(
                      color: theme.textSecondary, fontSize: 12, letterSpacing: 2)),
            )
          : ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: textDark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              onPressed: onTap,
              child: Text(label,
                  style: GoogleFonts.spaceMono(
                      fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 2)),
            ),
    );
  }
}

// ── Timer badge ───────────────────────────────────────────────────────────────

class _TimerBadge extends StatelessWidget {
  final int      seconds;
  final Color    color;
  final AppTheme theme;
  const _TimerBadge({required this.seconds, required this.color, required this.theme});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, color: color, size: 13),
          const SizedBox(width: 4),
          Text(
            '${seconds}s',
            style: GoogleFonts.spaceMono(
              color: color, fontSize: 13, fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
