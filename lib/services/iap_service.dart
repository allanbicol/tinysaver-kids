import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Service that handles the one-time "TinySaver Pro" unlock via
/// Apple App Store / Google Play billing using the `in_app_purchase` plugin.
///
/// ─── STORE SETUP (required before release) ────────────────────────────────
/// 1. App Store Connect → In-App Purchases → Non-Consumable
///    Product ID: `com.tinysaverkids.pro`
/// 2. Google Play Console → Monetize → Products → In-app products
///    Product ID: `com.tinysaverkids.pro`
/// 3. Upload a signed AAB to an Internal Testing track so Play returns real
///    product details in debug builds. Add your tester email.
/// 4. For a production-grade app, deploy a Firebase Cloud Function that
///    validates the receipt server-side (`androidPublisher.purchases.products`
///    or App Store Server API) and writes `is_premium=true` from the server.
///    The current implementation grants client-side — fine for MVP but
///    trivially bypassable on rooted devices.
///
/// Web / desktop: the plugin is unsupported on those platforms. `unlockPremium`
/// falls back to a direct Firestore write there (dev convenience only).
/// ────────────────────────────────────────────────────────────────────────────
class IapService {
  IapService._();
  static final instance = IapService._();

  static const String productId = 'com.tinysaverkids.pro';

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final InAppPurchase _iap = InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _sub;
  ProductDetails? _product;
  bool _available = false;
  bool _initialized = false;

  /// Tracks the currently-active purchase future so UI can await the result
  /// even though the native flow completes asynchronously via the purchase
  /// stream.
  Completer<PurchaseResult>? _pendingBuy;

  /// The UID of the user who initiated the current purchase — used to grant
  /// entitlement on success.
  String? _pendingUid;

  /// Set this to true while a restore is in flight so "no purchases" events
  /// get surfaced as `nothingToRestore` rather than silently ignored.
  bool _restoring = false;
  Completer<PurchaseResult>? _pendingRestore;

  /// User-facing price label (e.g. "₱299"). Falls back to a placeholder
  /// if the store hasn't returned product details yet.
  String get priceLabel => _product?.price ?? '₱299';

  /// Whether IAP is usable on this platform/device.
  bool get isAvailable => _available;

  /// Must be called once during app startup (after Firebase init).
  /// Safe to call multiple times; only the first call has effect.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Plugin is only supported on Android + iOS.
    if (kIsWeb) return;

    _available = await _iap.isAvailable();
    if (!_available) return;

    // Subscribe to purchase updates.
    _sub = _iap.purchaseStream.listen(
      _onPurchaseUpdates,
      onDone: () => _sub?.cancel(),
      onError: (e) => debugPrint('IAP stream error: $e'),
    );

    // Preload product details so the paywall shows the real localized price.
    final response = await _iap.queryProductDetails({productId});
    if (response.productDetails.isNotEmpty) {
      _product = response.productDetails.first;
    } else if (response.notFoundIDs.isNotEmpty) {
      debugPrint('IAP product not found in store: ${response.notFoundIDs}');
    }
  }

  /// Kicks off the Pro purchase flow. Resolves when the user completes
  /// or cancels the native sheet — UI can show a spinner while awaiting.
  Future<PurchaseResult> unlockPremium(String uid) async {
    // Web / desktop dev fallback: flip the flag directly.
    if (kIsWeb) return _grantDirect(uid);

    if (!_initialized) await init();
    if (!_available || _product == null) {
      // No store connection or product unavailable.
      if (kDebugMode) {
        // Dev escape hatch: still flip the flag so testing works without a
        // signed build on the internal testing track.
        return _grantDirect(uid);
      }
      return PurchaseResult.error;
    }

    // Don't allow two concurrent buys.
    if (_pendingBuy != null && !_pendingBuy!.isCompleted) {
      return PurchaseResult.error;
    }

    _pendingUid = uid;
    _pendingBuy = Completer<PurchaseResult>();

    try {
      final param = PurchaseParam(productDetails: _product!);
      final started = await _iap.buyNonConsumable(purchaseParam: param);
      if (!started) {
        _pendingBuy!.complete(PurchaseResult.error);
      }
    } catch (e) {
      debugPrint('IAP buy error: $e');
      _pendingBuy!.complete(PurchaseResult.error);
    }

    return _pendingBuy!.future;
  }

  /// Re-queries purchases from the store and grants entitlement if a valid
  /// Pro purchase is found. Safe to call on a fresh install.
  Future<PurchaseResult> restorePurchases(String uid) async {
    if (kIsWeb) {
      // Firestore already syncs in dev; nothing to do.
      return PurchaseResult.nothingToRestore;
    }
    if (!_initialized) await init();
    if (!_available) return PurchaseResult.error;

    _pendingUid = uid;
    _restoring = true;
    _pendingRestore = Completer<PurchaseResult>();

    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('IAP restore error: $e');
      _restoring = false;
      _pendingRestore?.complete(PurchaseResult.error);
      return PurchaseResult.error;
    }

    // Give the store ~3s to emit; if silent, assume nothing to restore.
    return _pendingRestore!.future.timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        _restoring = false;
        return PurchaseResult.nothingToRestore;
      },
    );
  }

  // ── internals ────────────────────────────────────────────────────────────

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (p.productID != productId) continue;

      switch (p.status) {
        case PurchaseStatus.pending:
          // Native sheet still open; nothing to do.
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // TODO(server-side): send p.verificationData.serverVerificationData
          // to a Cloud Function that validates with the store and writes
          // is_premium=true. Client-side grant below is MVP-only.
          final uid = _pendingUid;
          if (uid != null) {
            await _grantDirect(uid);
          }
          if (p.pendingCompletePurchase) {
            await _iap.completePurchase(p);
          }
          if (p.status == PurchaseStatus.restored && _restoring) {
            _restoring = false;
            _pendingRestore?.complete(PurchaseResult.success);
          } else {
            _pendingBuy?.complete(PurchaseResult.success);
          }
          break;
        case PurchaseStatus.error:
          debugPrint('IAP error: ${p.error}');
          _pendingBuy?.complete(PurchaseResult.error);
          if (_restoring) {
            _restoring = false;
            _pendingRestore?.complete(PurchaseResult.error);
          }
          if (p.pendingCompletePurchase) {
            await _iap.completePurchase(p);
          }
          break;
        case PurchaseStatus.canceled:
          _pendingBuy?.complete(PurchaseResult.cancelled);
          if (p.pendingCompletePurchase) {
            await _iap.completePurchase(p);
          }
          break;
      }
    }
  }

  Future<PurchaseResult> _grantDirect(String uid) async {
    try {
      await _db.collection('users').doc(uid).update({
        'is_premium': true,
        'premium_since': FieldValue.serverTimestamp(),
      });
      return PurchaseResult.success;
    } catch (e) {
      debugPrint('Firestore premium grant failed: $e');
      return PurchaseResult.error;
    }
  }

  void dispose() {
    _sub?.cancel();
  }
}

enum PurchaseResult { success, cancelled, error, nothingToRestore }
