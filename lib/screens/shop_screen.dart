// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/settings_state.dart';
import '../themes/app_themes.dart';
import '../services/ad_service.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});
  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  bool _watchingAd = false;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsState>();
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
                    Text('SHOP',
                        style: GoogleFonts.spaceMono(
                            color: theme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 3)),
                    const Spacer(),
                    // Coin balance
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFCC44).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color:
                                const Color(0xFFFFCC44).withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🪙', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text('${settings.coins}',
                              style: GoogleFonts.spaceMono(
                                  color: const Color(0xFFFFCC44),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700)),
                        ],
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

                    // ── Earn coins ─────────────────────────────
                    _sectionLabel('EARN COINS', theme),
                    const SizedBox(height: 12),
                    _EarnCard(
                      icon: '▶',
                      title: 'Watch a Rewarded Ad',
                      subtitle: '+5 coins per ad',
                      theme: theme,
                      loading: _watchingAd,
                      onTap: () => _watchAd(context, settings),
                    ),
                    const SizedBox(height: 8),
                    _EarnCard(
                      icon: '🎮',
                      title: 'Complete a Level',
                      subtitle: '+1 coin per level',
                      theme: theme,
                      onTap: null,
                    ),
                    const SizedBox(height: 8),
                    _EarnCard(
                      icon: '📅',
                      title: 'Daily Challenge',
                      subtitle: '+4 coins per day',
                      theme: theme,
                      onTap: null,
                    ),

                    const SizedBox(height: 28),

                    // ── Themes ─────────────────────────────────
                    _sectionLabel('THEMES', theme),
                    const SizedBox(height: 12),

                    ...AppThemes.all.map((t) {
                      final unlocked = settings.isThemeUnlocked(t.id);
                      final isCurrent = settings.themeId == t.id;
                      final canAfford = settings.coins >= t.coinCost;

                      return _ThemeShopCard(
                        appTheme: t,
                        currentTheme: theme,
                        unlocked: unlocked,
                        isCurrent: isCurrent,
                        canAfford: canAfford,
                        onBuy: () => _buyTheme(context, settings, theme, t),
                        onSelect: () => settings.setTheme(t.id),
                      );
                    }),

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

  Widget _sectionLabel(String text, AppTheme theme) => Text(
        text,
        style: GoogleFonts.spaceMono(
            color: theme.textSecondary,
            fontSize: 10,
            letterSpacing: 3,
            fontWeight: FontWeight.w700),
      );

  void _watchAd(BuildContext context, SettingsState settings) {
    if (!AdService().rewardedReady) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Ad not ready yet, try again shortly',
            style: GoogleFonts.spaceMono(fontSize: 11)),
        backgroundColor: AppThemes.byId(settings.themeId).cardBg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      return;
    }
    setState(() => _watchingAd = true);
    AdService().showRewarded(
      onRewarded: () async {
        await settings.addCoins(5);
        if (mounted) {
          setState(() => _watchingAd = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('🪙 +5 coins earned!',
                style: GoogleFonts.spaceMono(fontSize: 11)),
            backgroundColor: AppThemes.byId(settings.themeId).cardBg,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ));
        }
      },
    );
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _watchingAd = false);
    });
  }

  void _buyTheme(BuildContext context, SettingsState settings,
      AppTheme currentTheme, AppTheme t) async {
    final ok = await settings.tryUnlockTheme(t.id, t.coinCost);
    if (!mounted) return;
    if (ok) {
      settings.setTheme(t.id);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${t.emoji} ${t.name} unlocked!',
            style: GoogleFonts.spaceMono(fontSize: 11)),
        backgroundColor: currentTheme.cardBg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Not enough coins! Need ${t.coinCost} 🪙',
            style: GoogleFonts.spaceMono(fontSize: 11)),
        backgroundColor: currentTheme.cardBg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }
}

class _EarnCard extends StatelessWidget {
  final String icon, title, subtitle;
  final AppTheme theme;
  final VoidCallback? onTap;
  final bool loading;

  const _EarnCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.theme,
    this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: onTap != null
                  ? theme.accent.withValues(alpha: 0.4)
                  : theme.gridLine),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.spaceMono(
                          color: theme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                  Text(subtitle,
                      style: GoogleFonts.spaceMono(
                          color: theme.textSecondary, fontSize: 10)),
                ],
              ),
            ),
            if (onTap != null)
              loading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: theme.accent))
                  : Icon(Icons.play_circle_outline,
                      color: theme.accent, size: 22),
            if (onTap == null)
              Icon(Icons.info_outline,
                  color: theme.textSecondary.withValues(alpha: 0.4), size: 18),
          ],
        ),
      ),
    );
  }
}

class _ThemeShopCard extends StatelessWidget {
  final AppTheme appTheme, currentTheme;
  final bool unlocked, isCurrent, canAfford;
  final VoidCallback onBuy, onSelect;

  const _ThemeShopCard({
    required this.appTheme,
    required this.currentTheme,
    required this.unlocked,
    required this.isCurrent,
    required this.canAfford,
    required this.onBuy,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCurrent
            ? appTheme.accent.withValues(alpha: 0.1)
            : currentTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrent
              ? appTheme.accent
              : unlocked
                  ? currentTheme.gridLine
                  : currentTheme.gridLine.withValues(alpha: 0.5),
          width: isCurrent ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Color preview dots
          Column(
            children: [
              Row(children: [
                _dot(appTheme.arrowUp),
                const SizedBox(width: 3),
                _dot(appTheme.arrowRight),
              ]),
              const SizedBox(height: 3),
              Row(children: [
                _dot(appTheme.arrowLeft),
                const SizedBox(width: 3),
                _dot(appTheme.arrowDown),
              ]),
            ],
          ),
          const SizedBox(width: 12),
          Text(appTheme.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appTheme.name.toUpperCase(),
                    style: GoogleFonts.spaceMono(
                        color: isCurrent
                            ? appTheme.accent
                            : currentTheme.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1)),
                const SizedBox(height: 2),
                Text(
                    unlocked
                        ? (isCurrent ? 'Active' : 'Unlocked')
                        : '${appTheme.coinCost} coins',
                    style: GoogleFonts.spaceMono(
                        color: unlocked
                            ? currentTheme.textSecondary
                            : canAfford
                                ? const Color(0xFFFFCC44)
                                : currentTheme.textSecondary
                                    .withValues(alpha: 0.5),
                        fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isCurrent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: appTheme.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('ON',
                  style: GoogleFonts.spaceMono(
                      color: appTheme.accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
            )
          else if (unlocked)
            GestureDetector(
              onTap: onSelect,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: currentTheme.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: currentTheme.accent.withValues(alpha: 0.4)),
                ),
                child: Text('USE',
                    style: GoogleFonts.spaceMono(
                        color: currentTheme.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ),
            )
          else
            GestureDetector(
              onTap: canAfford ? onBuy : null,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: canAfford
                      ? const Color(0xFFFFCC44).withValues(alpha: 0.15)
                      : currentTheme.gridLine.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: canAfford
                          ? const Color(0xFFFFCC44).withValues(alpha: 0.6)
                          : currentTheme.gridLine.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🪙 ',
                        style: TextStyle(
                            fontSize: 10,
                            color: canAfford ? null : Colors.transparent)),
                    Text('BUY',
                        style: GoogleFonts.spaceMono(
                            color: canAfford
                                ? const Color(0xFFFFCC44)
                                : currentTheme.textSecondary
                                    .withValues(alpha: 0.4),
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _dot(Color c) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      );
}
