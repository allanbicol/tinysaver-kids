import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';

/// Renders the currently selected currency symbol (e.g. ₱, $, €) styled like an icon.
///
/// Always stays in sync with Firestore via [userStreamProvider]. Falls back to ₱
/// if the user doc hasn't loaded yet.
class CurrencySymbol extends ConsumerWidget {
  final double size;
  final Color color;
  final FontWeight weight;

  const CurrencySymbol({
    super.key,
    this.size = 20,
    this.color = Colors.black,
    this.weight = FontWeight.w800,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final symbol =
        ref.watch(userStreamProvider).valueOrNull?.currencySymbol ?? '₱';
    return Text(
      symbol,
      style: TextStyle(
        color: color,
        fontSize: size,
        fontWeight: weight,
        height: 1,
      ),
    );
  }
}

/// Same as [CurrencySymbol] but rendered inside a circular filled chip —
/// a drop-in visual replacement for `Icon(Icons.monetization_on_rounded)`.
class CurrencyCoinIcon extends ConsumerWidget {
  final double size;
  final Color? background;
  final Color symbolColor;

  const CurrencyCoinIcon({
    super.key,
    this.size = 20,
    this.background,
    this.symbolColor = Colors.white,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final symbol =
        ref.watch(userStreamProvider).valueOrNull?.currencySymbol ?? '₱';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: background ?? const Color(0xFF705D00),
      ),
      alignment: Alignment.center,
      child: Text(
        symbol,
        style: TextStyle(
          color: symbolColor,
          fontSize: size * 0.62,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}
