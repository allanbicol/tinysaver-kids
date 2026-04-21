import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles the native in-app review prompt (Google Play / App Store).
///
/// Google limits the prompt to 2 per year per user and silently no-ops if
/// the quota is exhausted — so we gate our *own* request by a set of
/// engagement heuristics and a 30-day cooldown stored in SharedPreferences.
///
/// Public surface:
///   • [maybePromptAfterCoinAdd] — called after a successful coin grant
///   • [openStoreListing] — force-open the store listing (manual button)
class ReviewService {
  ReviewService._();
  static final instance = ReviewService._();

  final InAppReview _review = InAppReview.instance;

  static const _kLastPrompted = 'review_last_prompted_at';
  static const _kCoinsSinceLast = 'review_coins_since_last';
  static const _kPromptedOnce = 'review_prompted_once';

  /// Called after each successful coin-add. Prompts after the user's
  /// 10th coin-add, then again 30+ days later. Does nothing on web.
  Future<void> maybePromptAfterCoinAdd() async {
    if (kIsWeb) return;

    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(_kCoinsSinceLast) ?? 0) + 1;
    await prefs.setInt(_kCoinsSinceLast, count);

    final threshold = prefs.getBool(_kPromptedOnce) == true ? 30 : 10;
    if (count < threshold) return;

    // 30-day cooldown from the last prompt (regardless of whether the user
    // actually submitted a review — Play/App Store track that themselves).
    final lastMs = prefs.getInt(_kLastPrompted) ?? 0;
    if (lastMs > 0) {
      final since = DateTime.now().millisecondsSinceEpoch - lastMs;
      if (since < const Duration(days: 30).inMilliseconds) return;
    }

    if (!await _review.isAvailable()) return;

    try {
      await _review.requestReview();
      await prefs.setInt(
        _kLastPrompted, DateTime.now().millisecondsSinceEpoch);
      await prefs.setInt(_kCoinsSinceLast, 0);
      await prefs.setBool(_kPromptedOnce, true);
    } catch (e) {
      debugPrint('requestReview failed: $e');
    }
  }

  /// Opens the Play Store / App Store listing for a manual rating.
  /// Used by the "Rate the App" button in the parent dashboard.
  Future<void> openStoreListing() async {
    if (kIsWeb) return;
    try {
      if (await _review.isAvailable()) {
        await _review.openStoreListing();
      }
    } catch (e) {
      debugPrint('openStoreListing failed: $e');
    }
  }
}
