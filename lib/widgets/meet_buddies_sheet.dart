import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/chunky_container.dart';
import '../widgets/pig_mascot.dart';

/// Kid-facing mascot preview.
/// No paywall — just a gentle "ask a parent" message on locked buddies.
class MeetBuddiesSheet extends ConsumerWidget {
  const MeetBuddiesSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userStreamProvider).valueOrNull;
    final isPro = user?.isPremium ?? false;
    final current = mascotKindFromId(user?.mascotKindId);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48, height: 5,
            decoration: BoxDecoration(
              color: AppColors.outlineVariant,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Text('🎪', style: TextStyle(fontSize: 30)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Meet the Buddies!',
                      style: Theme.of(context).textTheme.headlineMedium),
                    Text('Tap any friend to say hi 💛',
                      style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Flexible(
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.85,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: MascotKind.values.length,
              itemBuilder: (_, i) {
                final kind = MascotKind.values[i];
                final locked = kind.isPremium && !isPro;
                final active = kind == current;
                return _BuddyTile(
                  kind: kind,
                  locked: locked,
                  active: active,
                  onTap: () => _handleTap(context, ref, kind, locked),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleTap(BuildContext context, WidgetRef ref,
      MascotKind kind, bool locked) async {
    if (locked) {
      _showAskParent(context, kind);
      return;
    }
    // Free / already-Pro — just equip
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    await ref.read(firestoreServiceProvider).setMascot(uid, kind.id);
    if (context.mounted) Navigator.pop(context);
  }

  void _showAskParent(BuildContext context, MascotKind kind) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        backgroundColor: AppColors.surfaceContainerLowest,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PigMascot(
                pigState: PigState.happy,
                level: PigLevel.happy,
                kind: kind,
                size: 120,
              ),
              const SizedBox(height: 14),
              Text(kind.displayName,
                style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Ask a parent to unlock ${kind.displayName.split(' ').first} — they\'d love to play with you! 💛',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ChunkyButton(
                  onTap: () => Navigator.pop(context),
                  gradient: AppColors.primaryGradient,
                  shelfColor: AppColors.primaryDark,
                  shelfHeight: 5,
                  radius: 48,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text('Okay! 🤗',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BuddyTile extends StatelessWidget {
  final MascotKind kind;
  final bool locked, active;
  final VoidCallback onTap;

  const _BuddyTile({
    required this.kind,
    required this.locked,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChunkyButton(
      onTap: onTap,
      color: active
          ? AppColors.primaryContainer
          : AppColors.surfaceContainerLowest,
      shelfColor: active
          ? AppColors.primaryDark
          : AppColors.surfaceContainerHigh,
      shelfHeight: 5,
      radius: 22,
      padding: const EdgeInsets.all(8),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Opacity(
                opacity: locked ? 0.55 : 1.0,
                child: PigMascot(
                  pigState: PigState.normal,
                  level: PigLevel.happy,
                  kind: kind,
                  size: 74,
                ),
              ),
              const SizedBox(height: 4),
              Text(kind.displayName.split(' ').first,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: 12,
                  color: locked ? AppColors.outline : AppColors.onSurface,
                  fontWeight: FontWeight.w800)),
              if (active)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('YOURS',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 9)),
                  ),
                ),
            ],
          ),
          if (locked)
            Positioned(
              top: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.tertiaryDark,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_rounded,
                  color: Colors.white, size: 12),
              ),
            ),
        ],
      ),
    );
  }
}

void showMeetBuddies(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const MeetBuddiesSheet(),
  );
}
