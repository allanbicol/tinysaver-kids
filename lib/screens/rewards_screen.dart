import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import '../providers/app_providers.dart';
import '../models/reward_model.dart';
import '../theme/app_theme.dart';
import '../widgets/parent_pin_modal.dart';
import '../widgets/currency_symbol.dart';
import '../widgets/chunky_container.dart';
import '../services/sound_service.dart';

class RewardsScreen extends ConsumerStatefulWidget {
  const RewardsScreen({super.key});

  @override
  ConsumerState<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends ConsumerState<RewardsScreen> {
  late ConfettiController _confettiCtrl;

  @override
  void initState() {
    super.initState();
    _confettiCtrl = ConfettiController(duration: const Duration(seconds: 4));
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userStreamProvider).valueOrNull;
    final rewards = ref.watch(activeRewardsProvider).valueOrNull ?? [];
    final coins = user?.coinBalance ?? 0;
    final completedTasks = ref.watch(taskCompletionProvider).length;

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLow,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, rewards.length),
                Expanded(
                  child: rewards.isEmpty
                      ? _buildNoReward(context)
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          child: Column(
                            children: [
                              // Primary goal card
                              _buildMainCard(
                                context,
                                rewards.first.title,
                                rewards.first.emoji,
                                coins,
                                rewards.first.targetCoins,
                                (coins / rewards.first.targetCoins).clamp(0.0, 1.0),
                                coins >= rewards.first.targetCoins,
                                rewards.first.id,
                              ),
                              // Extra goals (Pro only shows >1)
                              if (rewards.length > 1) ...[
                                const SizedBox(height: 20),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text('More goals',
                                    style: Theme.of(context).textTheme.titleLarge),
                                ),
                                const SizedBox(height: 10),
                                ...rewards.skip(1).map((r) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _MiniGoalCard(
                                    reward: r,
                                    coins: coins,
                                    onRedeem: () => _redeemReward(r),
                                  ),
                                )),
                              ],
                              const SizedBox(height: 16),
                              _buildInfoRow(context, coins,
                                  rewards.first.targetCoins, completedTasks),
                              const SizedBox(height: 16),
                              _buildWantMoreRow(context),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiCtrl,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 40,
              gravity: 0.15,
              colors: const [
                AppColors.primary, AppColors.secondary, AppColors.tertiary,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int goalCount) {
    final title = goalCount > 1 ? 'My Goals' : 'My Goal';
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SAVINGS GOAL',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    letterSpacing: 1.5)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(title, style: Theme.of(context).textTheme.headlineLarge),
                    if (goalCount > 1) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('$goalCount',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ],
                ),
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
            child: const Icon(Icons.star_rounded,
              color: AppColors.tertiaryDark, size: 26),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCard(BuildContext context, String title, String emoji,
      int coins, int target, double progress, bool isComplete, String rewardId) {
    return ChunkyContainer(
      color: AppColors.surfaceContainerLowest,
      shelfColor: AppColors.surfaceContainerHigh,
      shelfHeight: 8,
      radius: 32,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Image / emoji area
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isComplete
                    ? [AppColors.secondaryContainer, AppColors.secondary.withValues(alpha: 0.5 * 255)]
                    : [AppColors.surfaceContainer, AppColors.surfaceContainerHigh],
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(emoji,
                    style: TextStyle(fontSize: isComplete ? 80 : 64)),
                ),
                Positioned(
                  bottom: 12, left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest.withValues(alpha: 0.9 * 255),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.flag_rounded,
                          color: AppColors.primaryDark, size: 14),
                        const SizedBox(width: 6),
                        Text(title.toUpperCase(),
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.primaryDark, letterSpacing: 1.2)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(title,
                        style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('GOAL AMOUNT',
                          style: Theme.of(context).textTheme.labelMedium),
                        Text('$target',
                          style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(color: AppColors.primaryDark)),
                        const CurrencySymbol(size: 18, color: AppColors.primaryDark),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Progress pill + counter
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isComplete
                            ? AppColors.secondaryContainer
                            : AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        isComplete
                            ? '100% there! 🎉'
                            : '${(progress * 100).toInt()}% there!',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: isComplete
                              ? AppColors.secondaryDark
                              : AppColors.primaryDark),
                      ),
                    ),
                    const Spacer(),
                    Text('$coins / $target',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700)),
                    const SizedBox(width: 4),
                    const CurrencySymbol(size: 14, color: AppColors.primaryDark),
                  ],
                ),
                const SizedBox(height: 12),
                // Segmented progress bar
                _SegmentedBar(progress: progress, segments: 10),
                const SizedBox(height: 20),
                // Redeem chunky button
                SizedBox(
                  width: double.infinity,
                  child: ChunkyButton(
                    onTap: isComplete ? _showRedeem : null,
                    disabled: !isComplete,
                    gradient: isComplete ? AppColors.tertiaryGradient : null,
                    color: isComplete ? null : AppColors.surfaceContainerHigh,
                    shelfColor: isComplete ? AppColors.tertiaryDark : AppColors.surfaceContainer,
                    shelfHeight: isComplete ? 7 : 3,
                    radius: 48,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      isComplete ? 'REDEEM REWARD 🎁' : 'REDEEM REWARD',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: isComplete ? AppColors.tertiaryDark : AppColors.outline,
                        letterSpacing: 1.5, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRedeem() {
    final rewards = ref.read(activeRewardsProvider).valueOrNull ?? [];
    if (rewards.isEmpty) return;
    _redeemReward(rewards.first);
  }

  void _redeemReward(RewardModel reward) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ParentPinModal(
        title: 'Redeem Reward',
        subtitle: 'Parent PIN needed to redeem',
        onApproved: () async {
          Navigator.pop(context);
          final uid = ref.read(currentUidProvider);
          if (uid == null) return;
          await ref.read(firestoreServiceProvider).redeemReward(uid, reward.id);
          final user = ref.read(userStreamProvider).valueOrNull;
          if (user != null) {
            final remaining =
                (user.coinBalance - reward.targetCoins).clamp(0, 999999).toInt();
            await ref.read(firestoreServiceProvider).updateCoinBalance(uid, remaining);
          }
          _confettiCtrl.play();
          ref.read(pigStateProvider.notifier).setExcited();
          SoundService.instance.success();    // 🎉 hurray chord
          if (mounted) _showCelebration(reward.title, reward.emoji);
        },
      ),
    );
  }

  void _showCelebration(String title, String emoji) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 72)),
              const SizedBox(height: 16),
              Text('Congratulations! 🎉',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('You earned: $title',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: AppColors.secondaryGradient,
                    borderRadius: BorderRadius.circular(48),
                  ),
                  child: Text('Yay! 🎊',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.secondaryDark, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, int coins, int target, int doneTasks) {
    final remaining = (target - coins).clamp(0, target);
    String motivation;
    String motEmoji;
    if (coins == 0) { motivation = 'Start completing tasks!'; motEmoji = '🚀'; }
    else if (coins < target * 0.5) { motivation = 'Only $remaining coins to go!'; motEmoji = '💪'; }
    else if (coins < target) { motivation = 'Almost there! $remaining more!'; motEmoji = '⚡'; }
    else { motivation = 'Time to claim your reward!'; motEmoji = '🎊'; }

    return Row(
      children: [
        Expanded(
          child: ChunkyContainer(
            color: AppColors.tertiaryContainer,
            shelfColor: AppColors.tertiaryDark,
            shelfHeight: 6,
            radius: 24,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(motEmoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 8),
                Text('Almost there!',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.tertiaryDark, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(motivation,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.tertiaryDark)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ChunkyContainer(
            color: AppColors.primaryContainer,
            shelfColor: AppColors.primaryDark,
            shelfHeight: 6,
            radius: 24,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🕐', style: TextStyle(fontSize: 28)),
                const SizedBox(height: 8),
                Text('Daily Streak',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primaryDark, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(doneTasks > 0
                    ? 'Done $doneTasks tasks today!'
                    : 'Complete tasks to start!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.primaryDark)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWantMoreRow(BuildContext context) {
    return ChunkyButton(
      onTap: () => ref.read(navIndexProvider.notifier).state = 1,
      color: AppColors.surfaceContainerLowest,
      shelfColor: AppColors.surfaceContainerHigh,
      shelfHeight: 5,
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.check_circle_outline_rounded,
                color: AppColors.secondaryDark, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Want more coins?',
                    style: Theme.of(context).textTheme.titleMedium),
                  Text('Complete daily chores to earn faster!',
                    style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
              color: AppColors.onSurfaceVariant, size: 16),
          ],
        ),
    );
  }

  Widget _buildNoReward(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88, height: 88,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.tertiaryContainer,
            ),
            child: const Icon(Icons.card_giftcard_rounded,
              color: AppColors.tertiaryDark, size: 44),
          ),
          const SizedBox(height: 20),
          Text('No reward set yet!',
            style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Ask your parent to set a reward goal.',
            style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _SegmentedBar extends StatelessWidget {
  final double progress;
  final int segments;
  const _SegmentedBar({required this.progress, required this.segments});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(segments, (i) {
        final filled = (i / segments) < progress;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < segments - 1 ? 4 : 0),
            height: 10,
            decoration: BoxDecoration(
              color: filled ? AppColors.primaryDark : AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        );
      }),
    );
  }
}

// ── Mini goal card for Pro users (extra concurrent rewards) ────────────────────
class _MiniGoalCard extends StatelessWidget {
  final RewardModel reward;
  final int coins;
  final VoidCallback onRedeem;

  const _MiniGoalCard({
    required this.reward,
    required this.coins,
    required this.onRedeem,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (coins / reward.targetCoins).clamp(0.0, 1.0);
    final isComplete = coins >= reward.targetCoins;

    return ChunkyContainer(
      color: AppColors.surfaceContainerLowest,
      shelfColor: AppColors.surfaceContainerHigh,
      shelfHeight: 5,
      radius: 24,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              gradient: isComplete
                  ? AppColors.secondaryGradient
                  : const LinearGradient(
                      colors: [AppColors.surfaceContainer, AppColors.surfaceContainerHigh]),
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: Text(reward.emoji, style: const TextStyle(fontSize: 32)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reward.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('$coins / ${reward.targetCoins}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark)),
                    const SizedBox(width: 3),
                    const CurrencySymbol(size: 13, color: AppColors.primaryDark),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: AppColors.surfaceContainerHigh,
                    valueColor: AlwaysStoppedAnimation(
                      isComplete ? AppColors.secondaryDark : AppColors.primaryDark),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (isComplete)
            ChunkyButton(
              onTap: onRedeem,
              gradient: AppColors.tertiaryGradient,
              shelfColor: AppColors.tertiaryDark,
              shelfHeight: 4,
              radius: 20,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Text('Redeem',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.tertiaryDark,
                  fontWeight: FontWeight.w800)),
            )
          else
            Text('${(progress * 100).toInt()}%',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.outline, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
