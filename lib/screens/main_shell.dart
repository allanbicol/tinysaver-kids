import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'tasks_screen.dart';
import 'rewards_screen.dart';
import 'buddy_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  bool _hasSyncedOnStart = false;

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(navIndexProvider);

    // On first frame with a loaded user: bump streak + ensure mission
    ref.listen(userStreamProvider, (_, next) {
      final user = next.valueOrNull;
      if (user == null || _hasSyncedOnStart) return;
      _hasSyncedOnStart = true;
      final fs = ref.read(firestoreServiceProvider);
      fs.recordActivity(user.id, user);
      fs.ensureDailyMission(user.id, user);
    });

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLow,
      body: IndexedStack(
        index: currentIndex,
        children: const [
          HomeScreen(),
          TasksScreen(),
          RewardsScreen(),
          BuddyScreen(),
        ],
      ),
      bottomNavigationBar: _BottomNav(currentIndex: currentIndex),
    );
  }
}

class _BottomNav extends ConsumerWidget {
  final int currentIndex;
  const _BottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.06 * 255),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: NavigationBar(
          selectedIndex: currentIndex,
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          indicatorColor: AppColors.primaryContainer,
          onDestinationSelected: (index) {
            ref.read(navIndexProvider.notifier).state = index;
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.savings_outlined),
              selectedIcon: Icon(Icons.savings_rounded),
              label: 'HOME',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined),
              selectedIcon: Icon(Icons.auto_awesome_rounded),
              label: 'TASKS',
            ),
            NavigationDestination(
              icon: Icon(Icons.card_giftcard_outlined),
              selectedIcon: Icon(Icons.card_giftcard_rounded),
              label: 'PRIZES',
            ),
            NavigationDestination(
              icon: Icon(Icons.face_outlined),
              selectedIcon: Icon(Icons.face_rounded),
              label: 'BUDDY',
            ),
          ],
        ),
      ),
    );
  }
}
