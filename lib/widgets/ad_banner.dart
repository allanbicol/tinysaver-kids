import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../providers/app_providers.dart';
import '../services/ad_service.dart';
import '../theme/app_theme.dart';

/// A banner ad that:
///  • Hides for Pro users
///  • Hides on web (AdMob not supported)
///  • Hides if no Ad Unit ID is configured or loading fails
///
/// Use **only in parent-facing screens** (BUDDY / Dashboard). The PIN gate
/// ensures kids never see ads.
class AdBanner extends ConsumerStatefulWidget {
  const AdBanner({super.key});

  @override
  ConsumerState<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends ConsumerState<AdBanner> {
  BannerAd? _ad;
  bool _loaded = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _maybeLoad();
  }

  void _maybeLoad() {
    if (kIsWeb) return;
    final unitId = AdService.instance.bannerUnitId;
    if (unitId == null) return;

    _ad = BannerAd(
      adUnitId: unitId,
      size: AdSize.banner,
      request: AdService.instance.bannerRequest,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
          if (mounted) setState(() => _failed = true);
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPro = ref.watch(userStreamProvider).valueOrNull?.isPremium ?? false;

    // Hide if Pro, on web, or if load failed / not yet loaded
    if (isPro || kIsWeb || _failed || !_loaded || _ad == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: _ad!.size.width.toDouble(),
      height: _ad!.size.height.toDouble(),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AdWidget(ad: _ad!),
      ),
    );
  }
}
