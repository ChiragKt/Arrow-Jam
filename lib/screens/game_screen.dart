import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../themes/game_themes.dart';
import '../services/audio_service.dart';
import '../widgets/maze_painter.dart';

class GameScreen extends StatefulWidget {
  final String themeId;
  const GameScreen({super.key, required this.themeId});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  Timer? _timer;
  late AnimationController _glowCtrl;
  late Animation<double> _glow;
  late AnimationController _overlayCtrl;

  bool _showHint = false;
  Offset? _dragStart;
  String? _lastMoveDir;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _glow = Tween(begin: 0.5, end: 1.0).animate(_glowCtrl);

    _overlayCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameState>().startLevel();
      _startTimer();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _glowCtrl.dispose();
    _overlayCtrl.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final gs = context.read<GameState>();
      gs.tick();
      if (gs.status == GameStatus.won || gs.status == GameStatus.lost) {
        _timer?.cancel();
        _overlayCtrl.forward(from: 0);
        if (gs.status == GameStatus.won) {
          context.read<AudioService>().playWin();
        } else {
          context.read<AudioService>().playLose();
        }
      }
    });
  }

  GameTheme get _theme => GameThemes.byId(widget.themeId);

  void _handleSwipe(String dir) {
    final gs = context.read<GameState>();
    final moved = gs.tryMove(dir);
    if (moved) {
      context.read<AudioService>().playMove();
      setState(() => _lastMoveDir = dir);
    } else {
      context.read<AudioService>().playWall();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = _theme;
    final gs = context.watch<GameState>();

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: theme.gradientColors,
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
                  Expanded(child: _buildMazeArea(theme, gs)),
                  _buildControls(theme, gs),
                ],
              ),
              if (gs.status == GameStatus.won || gs.status == GameStatus.lost)
                _buildOverlay(theme, gs),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHUD(GameTheme theme, GameState gs) {
    final timeRatio = gs.timeRemaining / gs.currentProfile.timeLimit;
    final timerColor = timeRatio > 0.5
        ? theme.uiAccent
        : timeRatio > 0.25
            ? Colors.orange
            : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(Icons.arrow_back_ios, color: theme.uiText.withOpacity(0.6), size: 20),
          ),
          const SizedBox(width: 12),
          // Lives
          Row(
            children: List.generate(
              3,
              (i) => Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  i < gs.lives ? Icons.favorite : Icons.favorite_border,
                  color: i < gs.lives ? Colors.redAccent : theme.uiText.withOpacity(0.2),
                  size: 18,
                ),
              ),
            ),
          ),
          const Spacer(),
          // Difficulty label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: theme.uiAccent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.uiAccent.withOpacity(0.3)),
            ),
            child: Text(
              gs.currentProfile.label,
              style: GoogleFonts.rajdhani(color: theme.uiAccent, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 10),
          // Level
          Text(
            'LVL ${gs.level}',
            style: GoogleFonts.orbitron(color: theme.uiText, fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 12),
          // Timer
          _TimerBadge(seconds: gs.timeRemaining, color: timerColor),
        ],
      ),
    );
  }

  Widget _buildMazeArea(GameTheme theme, GameState gs) {
    if (gs.status == GameStatus.idle) {
      return const Center(child: CircularProgressIndicator());
    }
    return GestureDetector(
      onPanStart: (d) => _dragStart = d.localPosition,
      onPanEnd: (d) {
        if (_dragStart == null) return;
        // Direction determined by velocity, not position delta, for responsiveness
        final vel = d.velocity.pixelsPerSecond;
        if (vel.distance < 100) return;
        String dir;
        if (vel.dx.abs() > vel.dy.abs()) {
          dir = vel.dx > 0 ? 'right' : 'left';
        } else {
          dir = vel.dy > 0 ? 'down' : 'up';
        }
        _handleSwipe(dir);
        _dragStart = null;
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: theme.pathColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.wallColor.withOpacity(0.3), width: 1.5),
              boxShadow: theme.isDark
                  ? [BoxShadow(color: theme.uiAccent.withOpacity(0.15), blurRadius: 20, spreadRadius: 2)]
                  : [],
            ),
            child: AnimatedBuilder(
              animation: _glow,
              builder: (_, __) => CustomPaint(
                painter: MazePainter(
                  maze: gs.maze,
                  playerCol: gs.playerCol,
                  playerRow: gs.playerRow,
                  goalCol: gs.goalCol,
                  goalRow: gs.goalRow,
                  theme: theme,
                  glowIntensity: _glow.value,
                ),
                child: Container(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControls(GameTheme theme, GameState gs) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20, top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SCORE', style: GoogleFonts.orbitron(color: theme.uiText.withOpacity(0.4), fontSize: 9, letterSpacing: 2)),
              Text('${gs.score}', style: GoogleFonts.orbitron(color: theme.uiAccent, fontSize: 20, fontWeight: FontWeight.w800)),
            ],
          ),
          // D-pad
          _DPad(theme: theme, onDir: _handleSwipe),
          // Hint
          Column(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() => _showHint = true);
                  Future.delayed(const Duration(seconds: 2), () {
                    if (mounted) setState(() => _showHint = false);
                  });
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.cardBackground.withOpacity(0.5),
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.uiAccent.withOpacity(0.3)),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _showHint
                        ? Text(
                            gs.hintDirection(),
                            key: const ValueKey('hint'),
                            style: TextStyle(fontSize: 22, color: theme.goalColor),
                          )
                        : Icon(Icons.lightbulb_outline, key: const ValueKey('bulb'), color: theme.uiText.withOpacity(0.5), size: 22),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text('HINT', style: GoogleFonts.orbitron(color: theme.uiText.withOpacity(0.3), fontSize: 9, letterSpacing: 2)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverlay(GameTheme theme, GameState gs) {
    final won = gs.status == GameStatus.won;
    return FadeTransition(
      opacity: _overlayCtrl,
      child: Container(
        color: Colors.black.withOpacity(0.75),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: theme.cardBackground,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: (won ? theme.goalColor : Colors.red).withOpacity(0.5), width: 2),
              boxShadow: [
                BoxShadow(
                  color: (won ? theme.goalColor : Colors.red).withOpacity(0.2),
                  blurRadius: 30,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(won ? '🎉' : '💀', style: const TextStyle(fontSize: 52)),
                const SizedBox(height: 12),
                Text(
                  won ? 'LEVEL CLEAR!' : 'GAME OVER',
                  style: GoogleFonts.orbitron(
                    color: won ? theme.goalColor : Colors.red,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  won ? 'Score: ${gs.score}' : 'Final Score: ${gs.score}',
                  style: GoogleFonts.rajdhani(color: theme.uiText, fontSize: 16),
                ),
                const SizedBox(height: 24),
                if (won) ...[
                  _OverlayBtn(
                    label: 'NEXT LEVEL',
                    color: theme.goalColor,
                    textDark: !theme.isDark,
                    onTap: () {
                      _overlayCtrl.reverse();
                      gs.startLevel();
                      _startTimer();
                    },
                  ),
                  const SizedBox(height: 10),
                ],
                _OverlayBtn(
                  label: won ? 'QUIT' : 'PLAY AGAIN',
                  color: won ? Colors.transparent : theme.uiAccent,
                  textDark: false,
                  outlined: won,
                  outlineColor: theme.uiText.withOpacity(0.3),
                  onTap: () {
                    if (won) {
                      Navigator.pop(context);
                    } else {
                      gs.resetGame();
                      gs.startLevel();
                      _overlayCtrl.reverse();
                      _startTimer();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimerBadge extends StatelessWidget {
  final int seconds;
  final Color color;
  const _TimerBadge({required this.seconds, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            '${seconds}s',
            style: GoogleFonts.orbitron(color: color, fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _DPad extends StatelessWidget {
  final GameTheme theme;
  final void Function(String) onDir;
  const _DPad({required this.theme, required this.onDir});

  Widget _btn(IconData icon, String dir) {
    return GestureDetector(
      onTap: () => onDir(dir),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: theme.cardBackground.withOpacity(0.6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.uiAccent.withOpacity(0.25)),
        ),
        child: Icon(icon, color: theme.uiText.withOpacity(0.8), size: 22),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _btn(Icons.keyboard_arrow_up, 'up'),
        const SizedBox(height: 4),
        Row(
          children: [
            _btn(Icons.keyboard_arrow_left, 'left'),
            const SizedBox(width: 4),
            Container(width: 44, height: 44),
            const SizedBox(width: 4),
            _btn(Icons.keyboard_arrow_right, 'right'),
          ],
        ),
        const SizedBox(height: 4),
        _btn(Icons.keyboard_arrow_down, 'down'),
      ],
    );
  }
}

class _OverlayBtn extends StatelessWidget {
  final String label;
  final Color color;
  final bool textDark, outlined;
  final Color? outlineColor;
  final VoidCallback onTap;
  const _OverlayBtn({
    required this.label, required this.color, required this.textDark,
    required this.onTap, this.outlined = false, this.outlineColor,
  });
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: outlined
          ? OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: outlineColor ?? Colors.white30),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: onTap,
              child: Text(label, style: GoogleFonts.orbitron(color: Colors.white70, fontSize: 13, letterSpacing: 2)),
            )
          : ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: textDark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: onTap,
              child: Text(label, style: GoogleFonts.orbitron(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 2)),
            ),
    );
  }
}
