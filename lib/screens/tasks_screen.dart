import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../models/task_model.dart';
import '../theme/app_theme.dart';
import '../widgets/parent_pin_modal.dart';
import '../widgets/currency_symbol.dart';
import '../widgets/chunky_container.dart';
import '../services/sound_service.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksStreamProvider);
    final completedIds = ref.watch(taskCompletionProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLow,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            tasksAsync.when(
              data: (tasks) => _buildProgressCard(context, completedIds.length, tasks.length),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: tasksAsync.when(
                data: (tasks) {
                  if (tasks.isEmpty) return _buildEmptyState(context);
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                    itemCount: tasks.length,
                    itemBuilder: (_, i) => _TaskCard(
                      task: tasks[i],
                      index: i,
                      isDone: completedIds.contains(tasks[i].id),
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primaryDark)),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('My Tasks',
                  style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 4),
                Text('Earn coins for every job done!',
                  style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.tertiaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
              color: AppColors.tertiaryDark, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context, int done, int total) {
    final progress = total == 0 ? 0.0 : done / total;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ChunkyContainer(
        color: AppColors.surfaceContainerLowest,
        shelfColor: AppColors.surfaceContainerHigh,
        shelfHeight: 5,
        radius: 24,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("TODAY'S GOAL",
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    letterSpacing: 1.2)),
                Text('$done/$total',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primaryDark, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: AppColors.surfaceContainerHigh,
                valueColor: const AlwaysStoppedAnimation(AppColors.primaryDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondaryContainer,
            ),
            child: const Icon(Icons.auto_awesome_rounded,
              color: AppColors.secondaryDark, size: 44),
          ),
          const SizedBox(height: 20),
          Text('No tasks yet!',
            style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Ask your parent to add some tasks.',
            style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _TaskCard extends ConsumerWidget {
  final TaskModel task;
  final int index;
  final bool isDone;

  const _TaskCard({required this.task, required this.index, required this.isDone});

  IconData _getIcon() {
    const map = {
      'bed': Icons.bed_rounded,
      'sentiment_very_satisfied': Icons.sentiment_very_satisfied_rounded,
      'eco': Icons.eco_rounded,
      'menu_book': Icons.menu_book_rounded,
      'toys': Icons.toys_rounded,
      'star': Icons.star_rounded,
      'cleaning_services': Icons.cleaning_services_rounded,
      'directions_run': Icons.directions_run_rounded,
      'brush': Icons.brush_rounded,
      'favorite': Icons.favorite_rounded,
    };
    return map[task.iconName] ?? Icons.star_rounded;
  }

  void _showPinModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ParentPinModal(
        onApproved: () async {
          Navigator.pop(context);
          await _approve(context, ref);
        },
      ),
    );
  }

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;

    final user = ref.read(userStreamProvider).valueOrNull;
    final prevLevel = user == null
        ? PigLevel.baby
        : pigLevelForCoins(user.coinBalance);

    final fs = ref.read(firestoreServiceProvider);
    await fs.logTaskCompletion(uid, task);
    await fs.addCoins(uid, task.coinReward);

    ref.read(taskCompletionProvider.notifier).markDone(task.id);
    ref.read(pigStateProvider.notifier).setHappy();
    SoundService.instance.coin();

    // Record activity + increment today's mission
    if (user != null) {
      await fs.recordActivity(uid, user);
      await fs.ensureDailyMission(uid, user);
      await fs.incrementMissionProgress(uid);
    }

    // Level up?
    if (user != null) {
      final newLevel = pigLevelForCoins(user.coinBalance + task.coinReward);
      final didLevelUp = newLevel.index > prevLevel.index;
      ref.read(pigLevelUpProvider.notifier).check(prevLevel, newLevel);
      if (didLevelUp) SoundService.instance.levelUp();
    }

    final reward = ref.read(activeRewardProvider).valueOrNull;
    if (user != null && reward != null &&
        user.coinBalance + task.coinReward >= reward.targetCoins) {
      ref.read(pigStateProvider.notifier).setExcited();
      ref.read(confettiProvider.notifier).play();
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('+${task.coinReward} coins earned! 🪙'),
        backgroundColor: AppColors.primaryDark,
        behavior: SnackBarBehavior.floating,
        shape: const StadiumBorder(),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iconBg = index.isEven
        ? AppColors.secondaryContainer
        : AppColors.tertiaryContainer;
    final iconColor = index.isEven
        ? AppColors.secondaryDark
        : AppColors.tertiaryDark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: ChunkyContainer(
        color: isDone ? AppColors.surfaceContainer : AppColors.surfaceContainerLowest,
        shelfColor: isDone ? AppColors.surfaceContainerHigh : AppColors.surfaceContainerHigh,
        shelfHeight: isDone ? 3 : 6,
        radius: 28,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Icon
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isDone
                        ? AppColors.surfaceContainerHigh
                        : iconBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(_getIcon(),
                    color: isDone ? AppColors.outline : iconColor, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isDone
                              ? AppColors.outline
                              : AppColors.onSurface,
                          decoration: isDone
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const CurrencySymbol(size: 14, color: AppColors.primaryDark),
                          const SizedBox(width: 4),
                          Text('+${task.coinReward} coins',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isDone
                                  ? AppColors.outline
                                  : AppColors.primaryDark,
                              fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Full-width chunky DONE button
            SizedBox(
              width: double.infinity,
              child: ChunkyButton(
                onTap: isDone ? null : () => _showPinModal(context, ref),
                disabled: isDone,
                gradient: isDone ? null : AppColors.primaryGradient,
                color: isDone ? AppColors.surfaceContainerHigh : null,
                shelfColor: isDone ? AppColors.surfaceContainer : AppColors.primaryDark,
                shelfHeight: isDone ? 3 : 6,
                radius: 48,
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  isDone ? 'FINISHED ✨' : 'DONE',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: isDone
                        ? AppColors.outline
                        : AppColors.primaryDark,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
