import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/chunky_container.dart';
import '../widgets/paywall_sheet.dart';

/// Kid-facing "Ask a parent to upgrade" popup shown when a child taps a
/// premium-locked item (Pro mascot, Pro accessory, etc.).
///
/// The kid never directly initiates a purchase — they hand the phone to a
/// parent, who can then continue to the real paywall.
Future<void> showAskParentDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return Dialog(
        backgroundColor: AppColors.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sparkle icon circle
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.auto_awesome_rounded,
                  color: AppColors.primaryDark, size: 36),
              ),
              const SizedBox(height: 18),
              Text('Ask a parent!',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              Text(
                'This is a Pro item. Show this to a grown-up — they can '
                'upgrade so you can use it.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.onSurfaceVariant)),
              const SizedBox(height: 24),
              // Primary action — continues to the paywall
              SizedBox(
                width: double.infinity,
                child: ChunkyButton(
                  onTap: () {
                    Navigator.of(ctx).pop();
                    showPaywall(context);
                  },
                  gradient: AppColors.primaryGradient,
                  shelfColor: AppColors.primaryDark,
                  shelfHeight: 6,
                  radius: 40,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text("I'm a parent — show me",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('Maybe later',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      );
    },
  );
}
