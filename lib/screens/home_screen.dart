import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../themes/app_themes.dart';
import 'game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _selectedLevel = 1;
  late AnimationController _fadeCtrl;
  late Animation<double> _fade;

  final GameTheme t = AppThemes.all[0];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() { _fadeCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: t.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 52),

                // Title
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'ARROW\n',
                        style: GoogleFonts.dmMono(
                          fontSize: 56, fontWeight: FontWeight.w900,
                          color: t.textPrimary, letterSpacing: 8, height: 1.1,
                        ),
                      ),
                      TextSpan(
                        text: 'JAM',
                        style: GoogleFonts.dmMono(
                          fontSize: 56, fontWeight: FontWeight.w900,
                          color: t.uiAccent, letterSpacing: 14, height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'free the arrows. clear the grid.',
                  style: GoogleFonts.dmMono(
                    fontSize: 13, color: t.textSecondary, letterSpacing: 1,
                  ),
                ),

                const SizedBox(height: 44),

                // How to play
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: t.cellBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: t.gridLine),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('HOW TO PLAY', style: GoogleFonts.dmMono(fontSize: 10, color: t.textSecondary, letterSpacing: 2)),
                      const SizedBox(height: 10),
                      _rule('👆', 'Tap an arrow to release it'),
                      _rule('➡️', 'It travels in its direction until it exits'),
                      _rule('🚫', 'Another arrow blocking it = lose a life'),
                      _rule('🧩', 'Find the right order to clear the grid'),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Level picker
                Text('START LEVEL', style: GoogleFonts.dmMono(fontSize: 10, color: t.textSecondary, letterSpacing: 2)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 48,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 15,
                    itemBuilder: (_, i) {
                      final lvl = i + 1;
                      final selected = lvl == _selectedLevel;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedLevel = lvl),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.only(right: 8),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: selected ? t.uiAccent : t.cellBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected ? t.uiAccent : t.gridLine,
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '$lvl',
                              style: GoogleFonts.dmMono(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: selected ? Colors.white : t.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 36),

                // Play button
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GameScreen(startLevel: _selectedLevel),
                    ),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: t.uiAccent,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(color: t.uiAccent.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
                    ),
                    child: Center(
                      child: Text(
                        'PLAY LEVEL $_selectedLevel',
                        style: GoogleFonts.dmMono(
                          color: Colors.white, fontSize: 18,
                          fontWeight: FontWeight.w800, letterSpacing: 3,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _chip('4×4 → 8×8 grids'),
                    const SizedBox(width: 8),
                    _chip('5 themes'),
                    const SizedBox(width: 8),
                    _chip('3 lives'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _rule(String emoji, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(children: [
      Text(emoji, style: const TextStyle(fontSize: 15)),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: GoogleFonts.dmMono(fontSize: 12, color: t.textPrimary))),
    ]),
  );

  Widget _chip(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: t.cellBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: t.gridLine)),
    child: Text(label, style: GoogleFonts.dmMono(fontSize: 10, color: t.textSecondary)),
  );
}
