import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._();
  factory AdService() => _instance;
  AdService._();

  static const String _interstitialId =
      'ca-app-pub-3940256099942544/1033173712'; // Google test interstitial

  static const String _rewardedId =
      'ca-app-pub-3940256099942544/5224354917'; // Google test rewarded

  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;

  bool _interstitialReady = false;
  bool _rewardedReady = false;

  /// Interstitial shows every N levels (every 3rd level complete).
  static const int interstitialEveryNLevels = 3;

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> init() async {
    await MobileAds.instance.initialize();
    _loadInterstitial();
    _loadRewarded();
  }

  // ── Interstitial ──────────────────────────────────────────────────────────

  void _loadInterstitial() {
    InterstitialAd.load(
      adUnitId: _interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          _interstitialReady = true;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitial = null;
              _interstitialReady = false;
              _loadInterstitial(); // pre-load next one
            },
            onAdFailedToShowFullScreenContent: (ad, _) {
              ad.dispose();
              _interstitial = null;
              _interstitialReady = false;
              _loadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (err) {
          debugPrint('[AdService] Interstitial failed to load: $err');
          _interstitialReady = false;
          Future.delayed(const Duration(seconds: 30), _loadInterstitial);
        },
      ),
    );
  }

  /// Call this after every level completes.
  /// The ad fires only on multiples of [interstitialEveryNLevels].
  void maybeShowInterstitial(int completedLevel) {
    if (completedLevel % interstitialEveryNLevels != 0) return;
    _showInterstitial();
  }

  void _showInterstitial() {
    if (!_interstitialReady || _interstitial == null) return;
    _interstitial!.show();
  }

  // ── Rewarded ──────────────────────────────────────────────────────────────

  void _loadRewarded() {
    RewardedAd.load(
      adUnitId: _rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded = ad;
          _rewardedReady = true;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewarded = null;
              _rewardedReady = false;
              _loadRewarded(); // pre-load next one
            },
            onAdFailedToShowFullScreenContent: (ad, _) {
              ad.dispose();
              _rewarded = null;
              _rewardedReady = false;
              _loadRewarded();
            },
          );
        },
        onAdFailedToLoad: (err) {
          debugPrint('[AdService] Rewarded failed to load: $err');
          _rewardedReady = false;
          Future.delayed(const Duration(seconds: 30), _loadRewarded);
        },
      ),
    );
  }

  bool get rewardedReady => _rewardedReady;

  /// Show a rewarded ad.
  /// [onRewarded] is called **only** if the user watches to completion.
  void showRewarded({required void Function() onRewarded}) {
    if (!_rewardedReady || _rewarded == null) return;
    _rewarded!.show(
      onUserEarnedReward: (_, __) => onRewarded(),
    );
  }
}
