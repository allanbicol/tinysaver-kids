import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Central ad configuration for TinySaver Kids.
///
/// IMPORTANT: ads only appear in parent-facing screens (BUDDY tab / Dashboard),
/// never in kid-facing screens. AdMob is configured for COPPA + GDPR-K
/// compliance: child-directed, non-personalized, G-rated ads only.
///
/// ─── TO GO TO PRODUCTION ────────────────────────────────────────────────────
/// 1. Create an AdMob account at https://admob.google.com
/// 2. Register this app:
///    • Package: com.tinysaverkids.tinysaver_kids   (Android)
///    • Bundle:  com.tinysaverkids.tinysaverKids    (iOS)
/// 3. Create a **banner** ad unit for each platform
/// 4. Replace [androidBannerUnitId] / [iosBannerUnitId] below with real IDs
/// 5. Add your App ID to:
///    • `android/app/src/main/AndroidManifest.xml` (inside the application tag):
///      `meta-data android:name="com.google.android.gms.ads.APPLICATION_ID"`
///      value: `ca-app-pub-XXXXXXXXXXXX~YYYYYYYYYY`
///    • `ios/Runner/Info.plist`:
///      key: `GADApplicationIdentifier`
///      value: `ca-app-pub-XXXXXXXXXXXX~YYYYYYYYYY`
/// ─────────────────────────────────────────────────────────────────────────────
class AdService {
  AdService._();
  static final instance = AdService._();

  /// Set to false once you configure real Ad Unit IDs.
  /// Test IDs always return test ads — safe to ship during dev, but never in prod.
  static const bool _useTestIds = true;

  // Google's official test IDs — always safe.
  static const _testBannerAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const _testBannerIos     = 'ca-app-pub-3940256099942544/2934735716';

  // Production IDs — replace these when going live.
  static const _prodBannerAndroid = 'ca-app-pub-0341990239025803/2252540691';
  static const _prodBannerIos     = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';

  bool _ready = false;
  bool get ready => _ready;

  /// Call once at app startup. Skips on web (AdMob doesn't run on web).
  Future<void> init() async {
    if (kIsWeb) return;
    await MobileAds.instance.initialize();
    // Kids-app compliance: force child-directed, non-personalized, G-rated.
    await MobileAds.instance.updateRequestConfiguration(RequestConfiguration(
      tagForChildDirectedTreatment: TagForChildDirectedTreatment.yes,
      tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.yes,
      maxAdContentRating: MaxAdContentRating.g,
    ));
    _ready = true;
  }

  /// Returns the banner Ad Unit ID for the current platform, or null
  /// (web / unsupported platforms / production IDs not set).
  String? get bannerUnitId {
    if (kIsWeb) return null;
    try {
      if (Platform.isAndroid) {
        return _useTestIds ? _testBannerAndroid : _prodBannerAndroid;
      }
      if (Platform.isIOS) {
        return _useTestIds ? _testBannerIos : _prodBannerIos;
      }
    } catch (_) { /* Platform not available */ }
    return null;
  }

  /// Standard COPPA-safe banner request.
  AdRequest get bannerRequest => const AdRequest(
    nonPersonalizedAds: true,
  );
}
