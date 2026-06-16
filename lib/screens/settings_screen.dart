import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/settings_state.dart';
import '../models/game_state.dart';
import '../themes/app_themes.dart';
import '../services/storage_service.dart';
import '../services/sound_service.dart';
import 'shop_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.arrow_back_ios,
                          color: theme.textSecondary, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Text('SETTINGS',
                        style: GoogleFonts.spaceMono(
                            color: theme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 3)),
                    const Spacer(),
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
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFFFCC44).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(0xFFFFCC44)
                                  .withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🪙', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 4),
                            Text('${settings.coins}',
                                style: GoogleFonts.spaceMono(
                                    color: const Color(0xFFFFCC44),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    const SizedBox(height: 8),

                    // ── Audio ──────────────────────────────────────────────
                    _SectionLabel('AUDIO', theme),
                    const SizedBox(height: 10),

                    // SFX toggle
                    _AudioRow(
                      icon: settings.soundEnabled
                          ? Icons.graphic_eq
                          : Icons.volume_off,
                      label: 'SFX',
                      sub: 'Tap & collision sounds',
                      value: settings.soundEnabled,
                      theme: theme,
                      onChanged: (_) {
                        settings.toggleSound();
                        SoundService().setSfxMuted(!settings.soundEnabled);
                      },
                    ),

                    const SizedBox(height: 8),

                    // Music toggle
                    _AudioRow(
                      icon: settings.musicEnabled
                          ? Icons.music_note
                          : Icons.music_off,
                      label: 'MUSIC',
                      sub: 'Ambient background music',
                      value: settings.musicEnabled,
                      theme: theme,
                      onChanged: (_) {
                        settings.toggleMusic();
                        SoundService().setMusicMuted(!settings.musicEnabled);
                      },
                    ),

                    const SizedBox(height: 8),

                    // Haptics toggle
                    _AudioRow(
                      icon: settings.hapticsEnabled
                          ? Icons.vibration
                          : Icons.phonelink_erase,
                      label: 'HAPTICS',
                      sub: 'Light vibration feedback',
                      value: settings.hapticsEnabled,
                      theme: theme,
                      onChanged: (_) {
                        settings.toggleHaptics();
                        SoundService()
                            .setHapticsMuted(!settings.hapticsEnabled);
                      },
                    ),

                    const SizedBox(height: 28),

                    // ── Difficulty ─────────────────────────────────────────
                    _SectionLabel('DIFFICULTY', theme),
                    const SizedBox(height: 12),
                    ...List.generate(kDifficulties.length, (i) {
                      final d = kDifficulties[i];
                      final selected = gs.difficultyIndex == i;
                      return GestureDetector(
                        onTap: () {
                          gs.setDifficulty(i);
                          SoundService().selectionClick();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 14),
                          decoration: BoxDecoration(
                            color: selected
                                ? theme.accent.withValues(alpha: 0.12)
                                : theme.cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected ? theme.accent : theme.gridLine,
                              width: selected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(d.emoji,
                                  style: const TextStyle(fontSize: 18)),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(d.label.toUpperCase(),
                                        style: GoogleFonts.spaceMono(
                                            color: selected
                                                ? theme.accent
                                                : theme.textPrimary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1)),
                                    Text(
                                        '${d.gridSize}×${d.gridSize} grid  •  ${d.lives} lives  •  ${d.timeSeconds}s',
                                        style: GoogleFonts.spaceMono(
                                            color: theme.textSecondary,
                                            fontSize: 10)),
                                  ],
                                ),
                              ),
                              if (selected)
                                Icon(Icons.check,
                                    color: theme.accent, size: 18),
                            ],
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 28),

                    // ── Data ───────────────────────────────────────────────
                    _SectionLabel('DATA', theme),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _confirmReset(context, theme),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 14),
                        decoration: BoxDecoration(
                          color: theme.cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.red.withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.delete_outline,
                                color: Colors.red, size: 20),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Reset Statistics',
                                      style: GoogleFonts.spaceMono(
                                          color: Colors.red,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 2),
                                  Text(
                                      'Clears games played, wins, game overs & best level',
                                      style: GoogleFonts.spaceMono(
                                          color: theme.textSecondary,
                                          fontSize: 9)),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right,
                                color: Colors.red.withValues(alpha: 0.6),
                                size: 18),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmReset(BuildContext context, AppTheme theme) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reset Stats?',
            style: GoogleFonts.spaceMono(
                color: theme.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 15)),
        content: Text(
            'This will permanently clear all your statistics — games played, wins, game overs, and best level. Coins and unlocked themes are kept.',
            style: GoogleFonts.spaceMono(
                color: theme.textSecondary, fontSize: 11, height: 1.6)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCEL',
                style: GoogleFonts.spaceMono(
                    color: theme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () async {
              await StorageService().resetAll();
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Statistics reset.',
                      style: GoogleFonts.spaceMono(fontSize: 12)),
                  backgroundColor: theme.cardBg,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  duration: const Duration(seconds: 2),
                ));
              }
            },
            child: Text('RESET',
                style: GoogleFonts.spaceMono(
                    color: Colors.red,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── Shared section label ───────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  final AppTheme theme;
  const _SectionLabel(this.text, this.theme);

  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.spaceMono(
          color: theme.textSecondary,
          fontSize: 10,
          letterSpacing: 3,
          fontWeight: FontWeight.w700));
}

// ── Audio toggle row ───────────────────────────────────────────────────────────

class _AudioRow extends StatelessWidget {
  final IconData icon;
  final String label, sub;
  final bool value;
  final AppTheme theme;
  final ValueChanged<bool> onChanged;

  const _AudioRow({
    required this.icon,
    required this.label,
    required this.sub,
    required this.value,
    required this.theme,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        decoration: BoxDecoration(
          color: theme.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value ? theme.accent.withValues(alpha: 0.3) : theme.gridLine,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: value ? theme.accent : theme.textSecondary, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.spaceMono(
                          color: theme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                  Text(sub,
                      style: GoogleFonts.spaceMono(
                          color: theme.textSecondary, fontSize: 9)),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: theme.accent,
              inactiveThumbColor: theme.textSecondary,
              inactiveTrackColor: theme.gridLine,
            ),
          ],
        ),
      ),
    );
  }
}
