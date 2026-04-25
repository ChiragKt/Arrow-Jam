import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async' show unawaited;
import 'models/game_state.dart';
import 'models/settings_state.dart';
import 'screens/home_screen.dart';
import 'services/sound_service.dart';
import 'services/ad_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  unawaited(SoundService().init());
  // FIX #1: await AdService().init() so MobileAds SDK is fully initialised
  // before _loadInterstitial() and _loadRewarded() are called.
  await AdService().init();
  runApp(const ArrowJamApp());
}

class ArrowJamApp extends StatelessWidget {
  const ArrowJamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsState()),
        ChangeNotifierProvider(create: (_) => GameState()),
      ],
      child: MaterialApp(
        title: 'Arrow Jam',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF070714),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
