import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../services/iap_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../widgets/chunky_container.dart';
import '../widgets/pig_mascot.dart';

class PaywallSheet extends ConsumerStatefulWidget {
  const PaywallSheet({super.key});

  @override
  ConsumerState<PaywallSheet> createState() => _PaywallSheetState();
}

class _PaywallSheetState extends ConsumerState<PaywallSheet> {
  bool _processing = false;

  Future<void> _buy() async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    setState(() => _processing = true);
    final result = await IapService.instance.unlockPremium(uid);
    if (!mounted) return;
    setState(() => _processing = false);

    if (result == PurchaseResult.success) {
      SoundService.instance.success();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('🎉 TinySaver Pro unlocked!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ));
    } else if (result == PurchaseResult.error) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Purchase failed. Please try again.'),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _restore() async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    final result = await IapService.instance.restorePurchases(uid);
    if (!mounted) return;
    final text = result == PurchaseResult.success
        ? '✅ Pro restored!'
        : 'No previous purchase found.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.secondaryDark,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userStreamProvider).valueOrNull;
    final alreadyPremium = user?.isPremium ?? false;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            children: [
              // Handle
              Container(
                width: 48, height: 5,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),

              // Hero: Rich pig with crown
              const PigMascot(
                pigState: PigState.excited,
                level: PigLevel.rich,
                accessoryId: 'royal_crown',
                size: 160,
              ),
              const SizedBox(height: 12),

              // Title
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.tertiaryDark],
                ).createShader(bounds),
                child: Text(
                  'TinySaver PRO',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Unlock everything. Forever.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 28),

              // Feature list
              const _Feature(
                icon: '🧙', title: 'Premium accessories',
                subtitle: 'Wizard hats, royal crowns & more',
              ),
              const _Feature(
                icon: '📊', title: 'Parent dashboard',
                subtitle: 'Weekly savings insights & habit graphs',
              ),
              const _Feature(
                icon: '🎯', title: 'Multiple reward goals',
                subtitle: 'Work toward many prizes at once',
              ),
              const _Feature(
                icon: '👨‍👩‍👧‍👦', title: 'Multi-child support',
                subtitle: 'One account for all your kids',
              ),
              const _Feature(
                icon: '💾', title: 'Export & backup',
                subtitle: 'Download savings history as PDF',
              ),
              const _Feature(
                icon: '🚫', title: 'No ads',
                subtitle: 'Remove all ads in the app, forever',
              ),

              const SizedBox(height: 24),

              if (alreadyPremium)
                ChunkyContainer(
                  color: AppColors.secondaryContainer,
                  shelfColor: AppColors.secondaryDark,
                  shelfHeight: 5,
                  radius: 20,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                        color: AppColors.secondaryDark, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text('You already own Pro — thanks! 🎉',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.secondaryDark,
                            fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                )
              else ...[
                // Price + buy button
                ChunkyContainer(
                  color: AppColors.surfaceContainerLowest,
                  shelfColor: AppColors.surfaceContainerHigh,
                  shelfHeight: 6,
                  radius: 24,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('One-time purchase',
                                style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(letterSpacing: 1.2)),
                              const SizedBox(height: 2),
                              Text('Pay once, keep forever',
                                style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(IapService.instance.priceLabel,
                                style: Theme.of(context).textTheme.displayMedium
                                  ?.copyWith(color: AppColors.primaryDark,
                                    fontSize: 36)),
                              Text('one-time',
                                style: Theme.of(context).textTheme.labelMedium),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ChunkyButton(
                    onTap: _processing ? null : _buy,
                    disabled: _processing,
                    gradient: AppColors.primaryGradient,
                    shelfColor: AppColors.primaryDark,
                    shelfHeight: 7,
                    radius: 48,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: _processing
                        ? const Center(child: SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(
                              color: AppColors.primaryDark, strokeWidth: 2.5)))
                        : Text('Unlock Pro 🎉',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w800, fontSize: 18)),
                  ),
                ),
              ],

              const SizedBox(height: 12),
              TextButton(
                onPressed: _restore,
                child: const Text('Restore purchase'),
              ),

              const SizedBox(height: 4),
              Text(
                'Non-refundable. One-time payment.',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.outline, letterSpacing: 0.3),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  final String icon, title, subtitle;
  const _Feature({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(icon, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800)),
                Text(subtitle,
                  style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper to open the paywall from anywhere.
void showPaywall(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const PaywallSheet(),
  );
}
