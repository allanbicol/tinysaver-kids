import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/chunky_container.dart';
import '../widgets/ask_parent_dialog.dart';
import '../widgets/pig_mascot.dart';

class MascotPickerSheet extends ConsumerWidget {
  const MascotPickerSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userStreamProvider).valueOrNull;
    final current = mascotKindFromId(user?.mascotKindId);
    final isPro = user?.isPremium ?? false;

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
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('✨', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Choose your mascot',
                      style: Theme.of(context).textTheme.headlineMedium),
                    Text('Your buddy will follow you everywhere',
                      style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            childAspectRatio: 0.82,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: MascotKind.values.map((k) {
              final locked = k.isPremium && !isPro;
              final selected = current == k;
              return _MascotTile(
                kind: k,
                selected: selected,
                locked: locked,
                onTap: () async {
                  if (locked) {
                    Navigator.pop(context);
                    showAskParentDialog(context);
                    return;
                  }
                  final uid = ref.read(currentUidProvider);
                  if (uid == null) return;
                  await ref.read(firestoreServiceProvider).setMascot(uid, k.id);
                  if (context.mounted) Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _MascotTile extends StatelessWidget {
  final MascotKind kind;
  final bool selected, locked;
  final VoidCallback onTap;

  const _MascotTile({
    required this.kind,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChunkyButton(
      onTap: onTap,
      color: selected
          ? AppColors.primaryContainer
          : AppColors.surfaceContainerLowest,
      shelfColor: selected
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
                opacity: locked ? 0.45 : 1.0,
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
              if (locked)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.tertiaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('PRO',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.tertiaryDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 9)),
                  ),
                )
              else if (selected)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('ACTIVE',
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
                child: const Icon(Icons.workspace_premium_rounded,
                  color: Colors.white, size: 12),
              ),
            ),
        ],
      ),
    );
  }
}

void showMascotPicker(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const MascotPickerSheet(),
  );
}
