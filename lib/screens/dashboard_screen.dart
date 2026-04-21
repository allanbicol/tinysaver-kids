import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_log_model.dart';
import '../models/reward_model.dart';
import '../providers/app_providers.dart';
import '../services/pdf_export_service.dart';
import '../theme/app_theme.dart';
import '../widgets/chunky_container.dart';
import '../widgets/currency_symbol.dart';
import '../widgets/paywall_sheet.dart';

/// Pro feature: parent insights with savings & habit charts.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userStreamProvider).valueOrNull;
    final isPro = user?.isPremium ?? false;

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLow,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            Expanded(
              child: isPro
                  ? _ProDashboard(uid: user!.id)
                  : _LockedView(context: context),
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
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                color: AppColors.onSurface),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('INSIGHTS',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    letterSpacing: 1.5)),
                const SizedBox(height: 2),
                Text('Parent Dashboard',
                  style: Theme.of(context).textTheme.headlineMedium),
              ],
            ),
          ),
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.analytics_rounded,
              color: AppColors.primaryDark),
          ),
        ],
      ),
    );
  }
}

// ── Locked view ──────────────────────────────────────────────────────────────
class _LockedView extends StatelessWidget {
  final BuildContext context;
  const _LockedView({required this.context});

  @override
  Widget build(BuildContext _) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100, height: 100,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
              ),
              child: const Icon(Icons.workspace_premium_rounded,
                color: AppColors.primaryDark, size: 52),
            ),
            const SizedBox(height: 20),
            Text('Parent Dashboard',
              style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Unlock Pro to see weekly savings trends,\nhabit streaks, and top tasks.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ChunkyButton(
              onTap: () => showPaywall(context),
              gradient: AppColors.primaryGradient,
              shelfColor: AppColors.primaryDark,
              shelfHeight: 6,
              radius: 48,
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
              child: Text('Unlock Pro',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pro dashboard content ────────────────────────────────────────────────────
class _ProDashboard extends ConsumerWidget {
  final String uid;
  const _ProDashboard({required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Load last 200 task logs (~last few months)
    final logsStream = FirebaseFirestore.instance
        .collection('users').doc(uid).collection('task_logs')
        .orderBy('created_at', descending: true)
        .limit(200)
        .snapshots()
        .map((snap) => snap.docs.map(TaskLogModel.fromFirestore).toList());

    return StreamBuilder<List<TaskLogModel>>(
      stream: logsStream,
      builder: (context, snap) {
        final logs = snap.data ?? [];
        final user = ref.watch(userStreamProvider).valueOrNull;

        final redeemed = ref.watch(redeemedRewardsProvider).valueOrNull ?? [];
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _statsRow(context, user, logs, redeemed),
              const SizedBox(height: 16),
              _weeklyBarChart(context, logs),
              const SizedBox(height: 16),
              _topTasksCard(context, logs),
              const SizedBox(height: 16),
              _streakCard(context, user),
              const SizedBox(height: 16),
              _redeemedGiftsCard(context, redeemed),
              const SizedBox(height: 16),
              _exportPdfButton(context, user, logs, redeemed),
            ],
          ),
        );
      },
    );
  }

  Widget _exportPdfButton(BuildContext context, user,
      List<TaskLogModel> logs, List<RewardModel> redeemed) {
    return SizedBox(
      width: double.infinity,
      child: ChunkyButton(
        onTap: user == null ? null : () async {
          try {
            await PdfExportService.instance.exportMonthlyReport(
              user: user,
              logs: logs,
              redeemed: redeemed,
            );
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('PDF export failed: $e'),
                backgroundColor: AppColors.danger,
                behavior: SnackBarBehavior.floating,
              ));
            }
          }
        },
        gradient: AppColors.secondaryGradient,
        shelfColor: AppColors.secondaryDark,
        shelfHeight: 6,
        radius: 24,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.picture_as_pdf_rounded,
              color: AppColors.secondaryDark, size: 22),
            const SizedBox(width: 10),
            Text('Export Monthly Report',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.secondaryDark, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  // ── Stats strip (3 cards) ──────────────────────────────────────────────────
  Widget _statsRow(BuildContext context, user, List<TaskLogModel> logs,
      List<RewardModel> redeemed) {
    final totalEarned = logs.fold<int>(0, (s, l) => s + l.coinsEarned);
    final thisWeek = logs.where((l) =>
        l.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 7))))
        .fold<int>(0, (s, l) => s + l.coinsEarned);

    return Row(
      children: [
        Expanded(
          child: _statTile(context,
            label: 'This Week',
            value: '$thisWeek',
            suffix: const CurrencySymbol(size: 16, color: AppColors.primaryDark),
            color: AppColors.primaryContainer,
            textColor: AppColors.primaryDark),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statTile(context,
            label: 'Total Earned',
            value: '$totalEarned',
            suffix: const CurrencySymbol(size: 16, color: AppColors.secondaryDark),
            color: AppColors.secondaryContainer,
            textColor: AppColors.secondaryDark),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statTile(context,
            label: 'Gifts Earned',
            value: '${redeemed.length}',
            color: AppColors.tertiaryContainer,
            textColor: AppColors.tertiaryDark),
        ),
      ],
    );
  }

  Widget _statTile(BuildContext context, {
    required String label, required String value,
    required Color color, required Color textColor, Widget? suffix,
  }) {
    return ChunkyContainer(
      color: color,
      shelfColor: textColor,
      shelfHeight: 5,
      radius: 20,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: textColor, letterSpacing: 0.8, fontSize: 10)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: textColor, fontSize: 28, fontWeight: FontWeight.w800)),
              if (suffix != null) Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 6),
                child: suffix,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Weekly bar chart (last 7 days coins earned) ────────────────────────────
  Widget _weeklyBarChart(BuildContext context, List<TaskLogModel> logs) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = List.generate(7, (i) =>
        today.subtract(Duration(days: 6 - i)));
    final dayTotals = <int>[];
    for (final d in days) {
      final total = logs.where((l) {
        final ld = DateTime(l.createdAt.year, l.createdAt.month, l.createdAt.day);
        return ld == d;
      }).fold<int>(0, (s, l) => s + l.coinsEarned);
      dayTotals.add(total);
    }
    final maxValue = (dayTotals.fold<int>(0, max) == 0 ? 1 : dayTotals.fold<int>(0, max));

    return ChunkyContainer(
      color: AppColors.surfaceContainerLowest,
      shelfColor: AppColors.surfaceContainerHigh,
      shelfHeight: 6,
      radius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('COINS EARNED · LAST 7 DAYS',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              letterSpacing: 1)),
          const SizedBox(height: 14),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final v = dayTotals[i];
                final heightFactor = v / maxValue;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (v > 0)
                          Text('$v',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDark)),
                        const SizedBox(height: 4),
                        Container(
                          height: (heightFactor * 100).clamp(2.0, 100.0),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                              bottom: Radius.circular(2)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(7, (i) {
              final d = days[i];
              return Expanded(
                child: Text(
                  _dayLabel(d),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.onSurfaceVariant),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  String _dayLabel(DateTime d) {
    const names = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return names[d.weekday - 1];
  }

  // ── Top tasks card ──────────────────────────────────────────────────────────
  Widget _topTasksCard(BuildContext context, List<TaskLogModel> logs) {
    final counts = <String, int>{};
    for (final l in logs) {
      counts[l.taskTitle] = (counts[l.taskTitle] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(5).toList();

    return ChunkyContainer(
      color: AppColors.surfaceContainerLowest,
      shelfColor: AppColors.surfaceContainerHigh,
      shelfHeight: 6,
      radius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🏆 TOP TASKS',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              letterSpacing: 1)),
          const SizedBox(height: 12),
          if (top.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('No completed tasks yet.',
                style: Theme.of(context).textTheme.bodyMedium),
            )
          else ...List.generate(top.length, (i) {
            final entry = top[i];
            final maxCount = top.first.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 26, height: 26,
                    decoration: BoxDecoration(
                      color: i == 0
                          ? AppColors.primaryContainer
                          : AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text('${i + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: i == 0 ? AppColors.primaryDark : AppColors.outline)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.key,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: entry.value / maxCount,
                            minHeight: 5,
                            backgroundColor: AppColors.surfaceContainerHigh,
                            valueColor: const AlwaysStoppedAnimation(
                              AppColors.primaryDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('${entry.value}×',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Streak card ────────────────────────────────────────────────────────────
  // ── Redeemed Gifts history ─────────────────────────────────────────────────
  Widget _redeemedGiftsCard(BuildContext context, List<RewardModel> redeemed) {
    return ChunkyContainer(
      color: AppColors.surfaceContainerLowest,
      shelfColor: AppColors.surfaceContainerHigh,
      shelfHeight: 6,
      radius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('🎁 REDEEMED GIFTS',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  letterSpacing: 1)),
              const Spacer(),
              if (redeemed.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.tertiaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${redeemed.length} total',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.tertiaryDark,
                      fontWeight: FontWeight.w800)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (redeemed.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Text('🎁', style: TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('No gifts redeemed yet. '
                      'Complete a goal to claim one!',
                      style: Theme.of(context).textTheme.bodyMedium),
                  ),
                ],
              ),
            )
          else
            ...redeemed.take(6).map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      gradient: AppColors.tertiaryGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(r.emoji, style: const TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800)),
                        Text(
                          r.redeemedAt != null
                              ? _formatRedeemedDate(r.redeemedAt!)
                              : 'Redeemed',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${r.targetCoins}',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w800)),
                        const SizedBox(width: 3),
                        const CurrencySymbol(size: 13,
                          color: AppColors.primaryDark),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          if (redeemed.length > 6)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('+ ${redeemed.length - 6} more in full report',
                style: Theme.of(context).textTheme.labelMedium),
            ),
        ],
      ),
    );
  }

  String _formatRedeemedDate(DateTime d) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  Widget _streakCard(BuildContext context, user) {
    final current = user?.currentStreak ?? 0;
    final longest = user?.longestStreak ?? 0;
    return ChunkyContainer(
      color: AppColors.tertiaryContainer,
      shelfColor: AppColors.tertiaryDark,
      shelfHeight: 6,
      radius: 24,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 48)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daily Streak',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.tertiaryDark, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text('$current day${current == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: AppColors.tertiaryDark, fontSize: 32)),
                const SizedBox(height: 2),
                Text('Personal best: $longest day${longest == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.tertiaryDark,
                    fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
