import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/settings_state.dart';
import '../themes/app_themes.dart';
import '../services/storage_service.dart';
import 'game_screen.dart';
import 'settings_screen.dart';
import 'shop_screen.dart';

enum _Panel { none, difficulty, custom }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  _Panel _panel = _Panel.none;
  Map<String, int> _stats = {
    'totalGamesPlayed': 0,
    'totalGameOvers': 0,
    'totalLevelClears': 0,
    'highestLevel': 0,
  };
  bool _dailyAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _checkDaily();
  }

  Future<void> _loadStats() async {
    final s = await StorageService().loadAllStats();
    if (mounted) setState(() => _stats = s);
  }

  Future<void> _checkDaily() async {
    final avail = await StorageService().isDailyChallengeAvailable();
    if (mounted) setState(() => _dailyAvailable = avail);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsState>();
    final gs = context.watch<GameState>();
    final theme = AppThemes.byId(settings.themeId);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: theme.bgGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                // ── Top bar: settings left, coin+shop right ─────────────
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    children: [
                      // Settings icon (top left)
                      GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SettingsScreen()));
                          _loadStats();
                          _checkDaily();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.cardBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: theme.gridLine),
                          ),
                          child: Icon(Icons.tune,
                              color: theme.textSecondary, size: 20),
                        ),
                      ),
                      const Spacer(),
                      // Coin balance + shop (top right)
                      GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ShopScreen()));
                          await settings.refreshCoins();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: theme.cardBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: const Color(0xFFFFCC44)
                                    .withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🪙', style: TextStyle(fontSize: 14)),
                              const SizedBox(width: 6),
                              Text('${settings.coins}',
                                  style: GoogleFonts.spaceMono(
                                      color: const Color(0xFFFFCC44),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(width: 6),
                              Icon(Icons.storefront_outlined,
                                  color: theme.textSecondary, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // Title
                Text('ARROW',
                    style: GoogleFonts.spaceMono(
                        color: theme.accent,
                        fontSize: 44,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 8,
                        height: 1.0)),
                Text('JAM',
                    style: GoogleFonts.spaceMono(
                        color: theme.textPrimary.withValues(alpha: 0.35),
                        fontSize: 44,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 16,
                        height: 1.0)),

                const SizedBox(height: 24),

                _StatsBanner(stats: _stats, theme: theme),

                const Spacer(flex: 2),

                // ── Daily Challenge button ─────────────────────────────
                if (_dailyAvailable && _panel == _Panel.none) ...[
                  _DailyChallengeButton(
                    theme: theme,
                    onTap: () => _startDailyChallenge(gs),
                  ),
                  const SizedBox(height: 14),
                ],

                // ── Mode area ─────────────────────────────────────────
                if (_panel == _Panel.none)
                  _buildModeSelection(theme, gs)
                else if (_panel == _Panel.difficulty)
                  _buildDifficultyPicker(theme, gs)
                else
                  _buildCustomPicker(theme, gs),

                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _startDailyChallenge(GameState gs) async {
    final claimed = await StorageService().claimDailyChallenge();
    if (!claimed) return;
    final gridSize = await StorageService().getDailyChallengeGridSize();
    gs.setCustom(gridSize);
    gs.startGame();
    if (!mounted) return;
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => const GameScreen()));
    // Award 4 daily coins
    if (mounted) {
      await context.read<SettingsState>().addCoins(4);
      setState(() {
        _panel = _Panel.none;
        _dailyAvailable = false;
      });
      _loadStats();
    }
  }

  Widget _buildModeSelection(AppTheme theme, GameState gs) {
    return Column(
      children: [
        Text('HOW DO YOU WANT TO PLAY?',
            style: GoogleFonts.spaceMono(
                color: theme.textSecondary, fontSize: 10, letterSpacing: 2)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
                child: _ModeCard(
                    emoji: '🎲',
                    label: 'RANDOM',
                    sub: 'Surprise difficulty',
                    theme: theme,
                    onTap: () {
                      gs.setRandomDifficulty(true);
                      _navigateToGame(gs);
                    })),
            const SizedBox(width: 10),
            Expanded(
                child: _ModeCard(
                    emoji: '🎯',
                    label: 'SELECT',
                    sub: 'Choose difficulty',
                    theme: theme,
                    onTap: () {
                      gs.setRandomDifficulty(false);
                      setState(() => _panel = _Panel.difficulty);
                    })),
            const SizedBox(width: 10),
            Expanded(
                child: _ModeCard(
                    emoji: '🔧',
                    label: 'CUSTOM',
                    sub: 'Pick grid size',
                    theme: theme,
                    onTap: () => setState(() => _panel = _Panel.custom))),
          ],
        ),
      ],
    );
  }

  Widget _buildDifficultyPicker(AppTheme theme, GameState gs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _backRow(theme, 'DIFFICULTY'),
        const SizedBox(height: 12),
        ...List.generate(kDifficulties.length, (i) {
          final d = kDifficulties[i];
          final selected = gs.difficultyIndex == i && !gs.isCustom;
          return GestureDetector(
            onTap: () => gs.setDifficulty(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: selected
                    ? theme.accent.withValues(alpha: 0.12)
                    : theme.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: selected ? theme.accent : theme.gridLine,
                    width: selected ? 1.5 : 1),
              ),
              child: Row(
                children: [
                  Text(d.emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.label.toUpperCase(),
                            style: GoogleFonts.spaceMono(
                                color:
                                    selected ? theme.accent : theme.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                        Text(
                            '${d.gridSize}×${d.gridSize}  •  ${d.timeSeconds}s  •  ${d.lives} lives',
                            style: GoogleFonts.spaceMono(
                                color: theme.textSecondary, fontSize: 9)),
                      ],
                    ),
                  ),
                  if (selected)
                    Icon(Icons.check, color: theme.accent, size: 16),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 10),
        _playButton(
          theme: theme,
          label: gs.difficultyIndex >= 0 && !gs.isCustom
              ? 'PLAY  •  ${kDifficulties[gs.difficultyIndex].label.toUpperCase()}'
              : 'PLAY',
          onTap: () => _navigateToGame(gs),
        ),
      ],
    );
  }

  Widget _buildCustomPicker(AppTheme theme, GameState gs) {
    final size = gs.isCustom ? gs.customGridSize : 5;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _backRow(theme, 'CUSTOM GRID'),
        const SizedBox(height: 18),
        Center(
            child: Text('$size × $size',
                style: GoogleFonts.spaceMono(
                    color: theme.accent,
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4))),
        Center(
            child: Text(
                '${size * size} cells  •  ~${(size * size * 2.5).toInt()}s  •  ${(size / 2).ceil().clamp(2, 6)} lives',
                style: GoogleFonts.spaceMono(
                    color: theme.textSecondary, fontSize: 10))),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: theme.accent,
            inactiveTrackColor: theme.gridLine,
            thumbColor: theme.accent,
            overlayColor: theme.accent.withValues(alpha: 0.15),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            trackHeight: 4,
          ),
          child: Slider(
            value: size.toDouble(),
            min: 3,
            max: 10,
            divisions: 7,
            onChanged: (v) => gs.setCustom(v.round()),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [3, 4, 5, 6, 7, 8, 9, 10]
                .map((s) => Text('$s',
                    style: GoogleFonts.spaceMono(
                        color: s == size ? theme.accent : theme.textSecondary,
                        fontSize: 9,
                        fontWeight:
                            s == size ? FontWeight.w700 : FontWeight.w400)))
                .toList(),
          ),
        ),
        const SizedBox(height: 18),
        _playButton(
            theme: theme,
            label: 'PLAY  •  $size×$size',
            onTap: () => _navigateToGame(gs)),
      ],
    );
  }

  Widget _backRow(AppTheme theme, String label) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => setState(() => _panel = _Panel.none),
          child:
              Icon(Icons.arrow_back_ios, color: theme.textSecondary, size: 16),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: GoogleFonts.spaceMono(
                color: theme.textSecondary, fontSize: 10, letterSpacing: 2)),
      ],
    );
  }

  Widget _playButton(
      {required AppTheme theme,
      required String label,
      required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.accent,
          foregroundColor: theme.isDark ? Colors.black : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        onPressed: onTap,
        child: Text(label,
            style: GoogleFonts.spaceMono(
                fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: 3)),
      ),
    );
  }

  void _navigateToGame(GameState gs) {
    gs.startGame();
    Navigator.push(
            context, MaterialPageRoute(builder: (_) => const GameScreen()))
        .then((_) {
      setState(() => _panel = _Panel.none);
      _loadStats();
      _checkDaily();
    });
  }
}

// ── Daily Challenge Button ─────────────────────────────────────────────────────

class _DailyChallengeButton extends StatelessWidget {
  final AppTheme theme;
  final VoidCallback onTap;
  const _DailyChallengeButton({required this.theme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFCC44).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: const Color(0xFFFFCC44).withValues(alpha: 0.5),
              width: 1.5),
        ),
        child: Row(
          children: [
            const Text('📅', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DAILY CHALLENGE',
                      style: GoogleFonts.spaceMono(
                          color: const Color(0xFFFFCC44),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1)),
                  Text('+4 coins  •  Available now!',
                      style: GoogleFonts.spaceMono(
                          color: const Color(0xFFFFCC44).withValues(alpha: 0.7),
                          fontSize: 9)),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: const Color(0xFFFFCC44).withValues(alpha: 0.7),
                size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Stats Banner ───────────────────────────────────────────────────────────────

class _StatsBanner extends StatelessWidget {
  final Map<String, int> stats;
  final AppTheme theme;
  const _StatsBanner({required this.stats, required this.theme});

  @override
  Widget build(BuildContext context) {
    final played = stats['totalGamesPlayed'] ?? 0;
    final clears = stats['totalLevelClears'] ?? 0;
    final overs = stats['totalGameOvers'] ?? 0;
    final highest = stats['highestLevel'] ?? 0;
    final winLabel = played == 0
        ? '—'
        : '${((clears / played) * 100).clamp(0, 9999).toStringAsFixed(0)}%';

    return Column(
      children: [
        Row(children: [
          Expanded(
              child: _StatCard(
                  icon: Icons.sports_esports_outlined,
                  label: 'PLAYED',
                  value: '$played',
                  theme: theme)),
          const SizedBox(width: 10),
          Expanded(
              child: _StatCard(
                  icon: Icons.emoji_events_outlined,
                  label: 'BEST LVL',
                  value: highest == 0 ? '—' : '$highest',
                  theme: theme,
                  highlight: true)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: _StatCard(
                  icon: Icons.trending_up_outlined,
                  label: 'WIN RATE',
                  value: winLabel,
                  theme: theme)),
          const SizedBox(width: 10),
          Expanded(
              child: _StatCard(
                  icon: Icons.close,
                  label: 'GAME OVERS',
                  value: '$overs',
                  theme: theme)),
        ]),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final AppTheme theme;
  final bool highlight;
  const _StatCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.theme,
      this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final valueColor = highlight ? theme.accent : theme.textPrimary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: highlight ? theme.accent.withValues(alpha: 0.08) : theme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: highlight
                ? theme.accent.withValues(alpha: 0.35)
                : theme.gridLine,
            width: highlight ? 1.5 : 1),
      ),
      child: Row(
        children: [
          Icon(icon,
              size: 16, color: highlight ? theme.accent : theme.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.spaceMono(
                        color: theme.textSecondary,
                        fontSize: 8,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(value,
                    style: GoogleFonts.spaceMono(
                        color: valueColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1.1)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String emoji, label, sub;
  final AppTheme theme;
  final VoidCallback onTap;
  const _ModeCard(
      {required this.emoji,
      required this.label,
      required this.sub,
      required this.theme,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: theme.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.gridLine),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(label,
                style: GoogleFonts.spaceMono(
                    color: theme.textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2)),
            const SizedBox(height: 2),
            Text(sub,
                style: GoogleFonts.spaceMono(
                    color: theme.textSecondary, fontSize: 8),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
