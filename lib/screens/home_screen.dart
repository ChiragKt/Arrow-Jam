import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../themes/game_themes.dart';
import '../models/game_state.dart';
import '../services/audio_service.dart';
import 'game_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  String _selectedThemeId = 'neon';
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulse = Tween(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    context.read<AudioService>().startMusic();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  GameTheme get _theme => GameThemes.byId(_selectedThemeId);

  @override
  Widget build(BuildContext context) {
    final theme = _theme;
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: theme.gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(theme),
              Expanded(child: _buildCenter(theme)),
              _buildThemePicker(theme),
              _buildBottomButtons(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(GameTheme theme) {
    final gs = context.watch<GameState>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StatChip(
            label: 'BEST',
            value: '${gs.highScore}',
            color: theme.uiAccent,
            textColor: theme.uiText,
          ),
          _AudioToggleRow(theme: theme),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            icon: Icon(Icons.settings_outlined, color: theme.uiText, size: 26),
          ),
        ],
      ),
    );
  }

  Widget _buildCenter(GameTheme theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ScaleTransition(
          scale: _pulse,
          child: Text(
            theme.emoji,
            style: const TextStyle(fontSize: 72),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'ARROW JAM',
          style: GoogleFonts.orbitron(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            color: theme.uiAccent,
            letterSpacing: 4,
            shadows: theme.isDark
                ? [Shadow(color: theme.uiAccent.withOpacity(0.6), blurRadius: 16)]
                : [],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'MAZE PUZZLE',
          style: GoogleFonts.orbitron(
            fontSize: 13,
            color: theme.uiText.withOpacity(0.6),
            letterSpacing: 6,
          ),
        ),
        const SizedBox(height: 40),
        _buildInstructions(theme),
      ],
    );
  }

  Widget _buildInstructions(GameTheme theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardBackground.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.uiAccent.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            'Swipe to navigate the maze',
            style: GoogleFonts.rajdhani(
              color: theme.uiText.withOpacity(0.9),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDot(theme.playerColor),
              Text('  You   ', style: TextStyle(color: theme.uiText.withOpacity(0.7), fontSize: 13)),
              _buildDot(theme.goalColor),
              Text('  Goal', style: TextStyle(color: theme.uiText.withOpacity(0.7), fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDot(Color c) => Container(
    width: 12, height: 12,
    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
  );

  Widget _buildThemePicker(GameTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, bottom: 10),
          child: Text(
            'THEME',
            style: GoogleFonts.orbitron(
              color: theme.uiText.withOpacity(0.5),
              fontSize: 11,
              letterSpacing: 3,
            ),
          ),
        ),
        SizedBox(
          height: 70,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: GameThemes.all.length,
            itemBuilder: (_, i) {
              final t = GameThemes.all[i];
              final selected = t.id == _selectedThemeId;
              return GestureDetector(
                onTap: () => setState(() => _selectedThemeId = t.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: selected ? 74 : 62,
                  decoration: BoxDecoration(
                    color: selected ? t.uiAccent.withOpacity(0.2) : theme.cardBackground.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected ? t.uiAccent : theme.uiText.withOpacity(0.15),
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(t.emoji, style: TextStyle(fontSize: selected ? 22 : 18)),
                      const SizedBox(height: 2),
                      Text(
                        t.name.split(' ').first,
                        style: GoogleFonts.rajdhani(
                          color: selected ? t.uiAccent : theme.uiText.withOpacity(0.5),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons(GameTheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.uiAccent,
                foregroundColor: theme.isDark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              onPressed: _startGame,
              child: Text(
                'START GAME',
                style: GoogleFonts.orbitron(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.uiText,
                side: BorderSide(color: theme.uiText.withOpacity(0.3)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
              child: Text(
                'SETTINGS',
                style: GoogleFonts.orbitron(fontSize: 13, letterSpacing: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startGame() {
    final gs = context.read<GameState>();
    gs.resetGame();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(themeId: _selectedThemeId),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label, value;
  final Color color, textColor;
  const _StatChip({required this.label, required this.value, required this.color, required this.textColor});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: GoogleFonts.orbitron(color: color, fontSize: 9, letterSpacing: 1)),
          const SizedBox(width: 6),
          Text(value, style: GoogleFonts.orbitron(color: textColor, fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _AudioToggleRow extends StatelessWidget {
  final GameTheme theme;
  const _AudioToggleRow({required this.theme});
  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioService>();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _AudioBtn(
          icon: audio.musicEnabled ? Icons.music_note : Icons.music_off,
          active: audio.musicEnabled,
          color: theme.uiAccent,
          dimColor: theme.uiText,
          onTap: audio.toggleMusic,
        ),
        const SizedBox(width: 6),
        _AudioBtn(
          icon: audio.sfxEnabled ? Icons.volume_up : Icons.volume_off,
          active: audio.sfxEnabled,
          color: theme.uiAccent,
          dimColor: theme.uiText,
          onTap: audio.toggleSfx,
        ),
      ],
    );
  }
}

class _AudioBtn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final Color color, dimColor;
  final VoidCallback onTap;
  const _AudioBtn({required this.icon, required this.active, required this.color, required this.dimColor, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: active ? color : dimColor.withOpacity(0.3), size: 22),
    );
  }
}
