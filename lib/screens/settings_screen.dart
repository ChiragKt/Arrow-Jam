import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/settings_state.dart';
import '../models/game_state.dart';
import '../themes/app_themes.dart';

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
              // Header
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
                    Text(
                      'SETTINGS',
                      style: GoogleFonts.spaceMono(
                        color: theme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
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

                    // ── Theme ──────────────────────────────────
                    _SectionLabel('THEME', theme),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: AppThemes.all.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1.4,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemBuilder: (_, i) {
                        final t = AppThemes.all[i];
                        final selected = t.id == settings.themeId;
                        return GestureDetector(
                          onTap: () => settings.setTheme(t.id),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: selected
                                  ? t.accent.withValues(alpha: 0.15)
                                  : theme.cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected ? t.accent : theme.gridLine,
                                width: selected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(t.emoji,
                                    style: const TextStyle(fontSize: 22)),
                                const SizedBox(height: 4),
                                Text(
                                  t.name.toUpperCase(),
                                  style: GoogleFonts.spaceMono(
                                    color: selected
                                        ? t.accent
                                        : theme.textSecondary,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 28),

                    // ── Difficulty ─────────────────────────────
                    _SectionLabel('DIFFICULTY', theme),
                    const SizedBox(height: 12),
                    ...List.generate(kDifficulties.length, (i) {
                      final d = kDifficulties[i];
                      final selected = gs.difficultyIndex == i;
                      return GestureDetector(
                        onTap: () => gs.setDifficulty(i),
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
                                    Text(
                                      d.label.toUpperCase(),
                                      style: GoogleFonts.spaceMono(
                                        color: selected
                                            ? theme.accent
                                            : theme.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${d.gridSize}×${d.gridSize} grid  •  ${d.lives} lives  •  ${d.timeSeconds}s',
                                      style: GoogleFonts.spaceMono(
                                        color: theme.textSecondary,
                                        fontSize: 10,
                                      ),
                                    ),
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

                    // ── Sound ──────────────────────────────────
                    _SectionLabel('SOUND', theme),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => settings.toggleSound(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 14),
                        decoration: BoxDecoration(
                          color: theme.cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.gridLine),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              settings.soundEnabled
                                  ? Icons.volume_up
                                  : Icons.volume_off,
                              color: settings.soundEnabled
                                  ? theme.accent
                                  : theme.textSecondary,
                              size: 20,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                'Sound Effects',
                                style: GoogleFonts.spaceMono(
                                  color: theme.textPrimary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Switch(
                              value: settings.soundEnabled,
                              onChanged: (_) => settings.toggleSound(),
                              activeThumbColor: theme.accent,
                              inactiveThumbColor: theme.textSecondary,
                              inactiveTrackColor: theme.gridLine,
                            ),
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
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final AppTheme theme;
  const _SectionLabel(this.text, this.theme);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.spaceMono(
          color: theme.textSecondary,
          fontSize: 10,
          letterSpacing: 3,
          fontWeight: FontWeight.w700,
        ),
      );
}
