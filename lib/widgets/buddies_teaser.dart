import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/chunky_container.dart';
import '../widgets/meet_buddies_sheet.dart';
import '../widgets/pig_mascot.dart';

/// Small rotating card that cycles through locked Pro mascots.
/// Tap → opens MeetBuddiesSheet. Hides itself if the user owns Pro.
class BuddiesTeaser extends ConsumerStatefulWidget {
  const BuddiesTeaser({super.key});

  @override
  ConsumerState<BuddiesTeaser> createState() => _BuddiesTeaserState();
}

class _BuddiesTeaserState extends ConsumerState<BuddiesTeaser> {
  int _index = 0;
  Timer? _timer;

  List<MascotKind> get _pool =>
      MascotKind.values.where((k) => k.isPremium).toList();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % _pool.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userStreamProvider).valueOrNull;
    // Hide the teaser entirely for Pro users — they already have everything.
    if (user?.isPremium ?? false) return const SizedBox.shrink();

    final kind = _pool[_index];
    final blurb = _blurbFor(kind);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ChunkyButton(
        onTap: () => showMeetBuddies(context),
        color: AppColors.surfaceContainerLowest,
        shelfColor: AppColors.surfaceContainerHigh,
        shelfHeight: 5,
        radius: 22,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Rotating mascot preview with crossfade
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(scale: anim, child: child),
              ),
              child: PigMascot(
                key: ValueKey(kind),
                pigState: PigState.happy,
                level: PigLevel.happy,
                kind: kind,
                size: 50,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Column(
                  key: ValueKey(kind),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('MEET MORE BUDDIES',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                            fontSize: 10,
                          )),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('${_pool.length}',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w800,
                              fontSize: 9)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(blurb,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      )),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_ios_rounded,
              color: AppColors.outlineVariant, size: 14),
          ],
        ),
      ),
    );
  }

  String _blurbFor(MascotKind k) {
    final name = k.displayName.split(' ').first;
    final emoji = k.emoji;
    return switch (k) {
      MascotKind.bunny   => '$emoji $name wants to hop by!',
      MascotKind.bear    => '$emoji $name brought a hug!',
      MascotKind.cat     => '$emoji $name says meow!',
      MascotKind.fox     => '$emoji $name is so sneaky!',
      MascotKind.panda   => '$emoji $name loves bamboo!',
      MascotKind.unicorn => '$emoji $name has magic!',
      MascotKind.robot   => '$emoji $name goes beep boop!',
      MascotKind.plant   => '$emoji $name wants to grow!',
      MascotKind.birdie  => '$emoji $name tweets hello!',
      _                  => '$emoji Meet $name!',
    };
  }
}
