import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/accessory.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/chunky_container.dart';
import '../widgets/currency_symbol.dart';
import '../widgets/pig_mascot.dart';
import '../widgets/ask_parent_dialog.dart';

class AccessoryShopSheet extends ConsumerWidget {
  const AccessoryShopSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userStreamProvider).valueOrNull;
    final pigLevel = ref.watch(pigLevelProvider);
    final owned = user?.ownedAccessories ?? const <String>[];
    final worn = user?.wornAccessory;
    final balance = user?.coinBalance ?? 0;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.outlineVariant,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('🛍️', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Buddy Shop',
                      style: Theme.of(context).textTheme.headlineMedium),
                    Text('Dress up ${user?.pigName ?? 'your piggy'}!',
                      style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              // Balance pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$balance',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primaryDark, fontWeight: FontWeight.w800)),
                    const SizedBox(width: 4),
                    const CurrencySymbol(size: 16, color: AppColors.primaryDark),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // "None" option to remove worn accessory
          if (owned.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ChunkyButton(
                onTap: worn == null
                    ? null
                    : () async {
                        final uid = ref.read(currentUidProvider);
                        if (uid == null) return;
                        await ref.read(firestoreServiceProvider)
                            .setWornAccessory(uid, null);
                      },
                color: worn == null
                    ? AppColors.tertiaryContainer
                    : AppColors.surfaceContainerLowest,
                shelfColor: AppColors.surfaceContainerHigh,
                shelfHeight: 4,
                radius: 20,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.block_rounded,
                      color: AppColors.onSurfaceVariant, size: 18),
                    const SizedBox(width: 10),
                    Text('No accessory',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700)),
                    const Spacer(),
                    if (worn == null)
                      const Icon(Icons.check_circle_rounded,
                        color: AppColors.tertiaryDark, size: 20),
                  ],
                ),
              ),
            ),

          // Catalog
          Flexible(
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: kAccessories.length,
              itemBuilder: (_, i) {
                final a = kAccessories[i];
                final isOwned = owned.contains(a.id);
                final isWorn = worn == a.id;
                final canAfford = balance >= a.price;
                final isLocked = a.isPremium && !(user?.isPremium ?? false);
                final mascotKind = mascotKindFromId(user?.mascotKindId);
                return _AccessoryTile(
                  accessory: a,
                  pigLevel: pigLevel,
                  mascotKind: mascotKind,
                  isOwned: isOwned,
                  isWorn: isWorn,
                  canAfford: canAfford,
                  isLocked: isLocked,
                  onTap: () {
                    if (isLocked) {
                      Navigator.pop(context);       // close shop
                      showAskParentDialog(context);
                      return;
                    }
                    _onTileTap(context, ref, a, isOwned, isWorn, canAfford);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onTileTap(BuildContext context, WidgetRef ref, Accessory a,
      bool owned, bool worn, bool canAfford) async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    final fs = ref.read(firestoreServiceProvider);

    if (owned) {
      // Toggle equip/unequip
      await fs.setWornAccessory(uid, worn ? null : a.id);
    } else {
      if (!canAfford) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Not enough coins for ${a.name}!'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ));
        return;
      }
      // Confirm buy
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Buy ${a.name}?'),
          content: Text('This will cost ${a.price} coins.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Buy')),
          ],
        ),
      );
      if (ok == true) {
        await fs.purchaseAccessory(uid, a.id, a.price);
        await fs.setWornAccessory(uid, a.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('🎉 Got ${a.name}!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ));
        }
      }
    }
  }
}

class _AccessoryTile extends StatelessWidget {
  final Accessory accessory;
  final PigLevel pigLevel;
  final MascotKind mascotKind;
  final bool isOwned, isWorn, canAfford, isLocked;
  final VoidCallback onTap;

  const _AccessoryTile({
    required this.accessory,
    required this.pigLevel,
    required this.mascotKind,
    required this.isOwned,
    required this.isWorn,
    required this.canAfford,
    required this.isLocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isWorn
        ? AppColors.primaryContainer
        : AppColors.surfaceContainerLowest;
    final accent = isWorn ? AppColors.primaryDark : AppColors.surfaceContainerHigh;

    return ChunkyButton(
      onTap: onTap,
      color: bg,
      shelfColor: accent,
      shelfHeight: 5,
      radius: 22,
      padding: const EdgeInsets.all(10),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Preview pig with accessory
              Opacity(
                opacity: isLocked ? 0.45 : 1.0,
                child: PigMascot(
                  pigState: PigState.normal,
                  level: pigLevel,
                  accessoryId: accessory.id,
                  kind: mascotKind,
                  size: 84,
                ),
              ),
              const SizedBox(height: 6),
              Text(accessory.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800, fontSize: 13,
                  color: isLocked ? AppColors.outline : AppColors.onSurface)),
              const SizedBox(height: 4),
              if (isLocked)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.tertiaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_rounded,
                        color: AppColors.tertiaryDark, size: 10),
                      const SizedBox(width: 3),
                      Text('PRO',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.tertiaryDark,
                          fontWeight: FontWeight.w800, fontSize: 10,
                          letterSpacing: 0.5)),
                    ],
                  ),
                )
              else if (isWorn)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('WEARING',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white, fontWeight: FontWeight.w800, fontSize: 10)),
            )
          else if (isOwned)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('OWNED · TAP TO WEAR',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.secondaryDark,
                  fontWeight: FontWeight.w800, fontSize: 9)),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${accessory.price}',
                  style: TextStyle(
                    color: canAfford ? AppColors.primaryDark : AppColors.outline,
                    fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(width: 3),
                CurrencySymbol(
                  size: 13,
                  color: canAfford ? AppColors.primaryDark : AppColors.outline),
              ],
            ),
            ],
          ),
          // Pro crown ribbon corner badge (locked items only)
          if (isLocked)
            Positioned(
              top: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.tertiaryDark,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.workspace_premium_rounded,
                  color: Colors.white, size: 14),
              ),
            ),
        ],
      ),
    );
  }
}
