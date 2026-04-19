import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/audio_service.dart';
import '../themes/game_themes.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioService>();
    final theme = GameThemes.all[0]; // Use neon as settings UI theme
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'SETTINGS',
          style: GoogleFonts.orbitron(color: Colors.white, fontSize: 16, letterSpacing: 4),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SectionHeader('AUDIO'),
          _ToggleTile(
            icon: Icons.music_note,
            label: 'Background Music',
            subtitle: 'Play ambient music during game',
            value: audio.musicEnabled,
            accentColor: const Color(0xFF00FFFF),
            onChanged: (_) => audio.toggleMusic(),
          ),
          _ToggleTile(
            icon: Icons.volume_up,
            label: 'Sound Effects',
            subtitle: 'Play sounds for moves and events',
            value: audio.sfxEnabled,
            accentColor: const Color(0xFF00FFFF),
            onChanged: (_) => audio.toggleSfx(),
          ),
          const SizedBox(height: 24),
          _SectionHeader('HOW TO PLAY'),
          _InfoCard(
            icon: '👆',
            title: 'Swipe to Move',
            body: 'Swipe in any direction to move your dot through the maze.',
          ),
          _InfoCard(
            icon: '🎯',
            title: 'Reach the Goal',
            body: 'Navigate to the glowing goal dot before the timer runs out.',
          ),
          _InfoCard(
            icon: '🧠',
            title: 'Adaptive Difficulty',
            body: 'Solve fast and the maze grows harder. Take your time and it eases up.',
          ),
          _InfoCard(
            icon: '💡',
            title: 'Hint Arrow',
            body: 'Tap the hint button for a direction arrow pointing toward the goal.',
          ),
          _InfoCard(
            icon: '❤️',
            title: 'Lives',
            body: 'You have 3 lives. Running out of time costs one life.',
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              'Arrow Jam v2.0',
              style: GoogleFonts.orbitron(
                color: Colors.white24,
                fontSize: 11,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      text,
      style: GoogleFonts.orbitron(
        color: const Color(0xFF00FFFF).withOpacity(0.6),
        fontSize: 11,
        letterSpacing: 3,
      ),
    ),
  );
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final bool value;
  final Color accentColor;
  final ValueChanged<bool> onChanged;
  const _ToggleTile({
    required this.icon, required this.label, required this.subtitle,
    required this.value, required this.accentColor, required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF12122A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: value ? accentColor : Colors.white24, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
              Text(subtitle, style: GoogleFonts.rajdhani(color: Colors.white38, fontSize: 12)),
            ]),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: accentColor,
            inactiveThumbColor: Colors.white24,
            inactiveTrackColor: Colors.white10,
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String icon, title, body;
  const _InfoCard({required this.icon, required this.title, required this.body});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(body, style: GoogleFonts.rajdhani(color: Colors.white54, fontSize: 13)),
            ]),
          ),
        ],
      ),
    );
  }
}
