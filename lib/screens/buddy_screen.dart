import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../models/task_model.dart';
import '../models/reward_model.dart';
import '../theme/app_theme.dart';
import '../services/review_service.dart';
import '../widgets/parent_pin_modal.dart';
import '../widgets/currency_symbol.dart';
import '../widgets/chunky_container.dart';
import '../widgets/paywall_sheet.dart';
import '../widgets/mascot_picker_sheet.dart';
import '../widgets/ad_banner.dart';
import 'dashboard_screen.dart';

// ── Pin Gate Provider (local to BUDDY tab) ────────────────────────────────────
final _buddyUnlockedProvider = StateProvider<bool>((ref) => false);

class BuddyScreen extends ConsumerWidget {
  const BuddyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUnlocked = ref.watch(_buddyUnlockedProvider);
    return isUnlocked
        ? const _ParentDashboard()
        : _PinGateView(onUnlocked: () {
            ref.read(_buddyUnlockedProvider.notifier).state = true;
          });
  }
}

// ── PIN Gate ──────────────────────────────────────────────────────────────────
class _PinGateView extends ConsumerWidget {
  final VoidCallback onUnlocked;
  const _PinGateView({required this.onUnlocked});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userStreamProvider).valueOrNull;
    final isDefaultPin = user?.pinCode == '1234';

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLow,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100, height: 100,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondaryContainer,
                ),
                child: const Icon(Icons.lock_rounded,
                  color: AppColors.secondaryDark, size: 52),
              ),
              const SizedBox(height: 24),
              Text('Parent Mode',
                style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 8),
              Text('Manage tasks, rewards & settings',
                style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: SizedBox(
                  width: double.infinity,
                  child: ChunkyButton(
                    onTap: () => _showPin(context),
                    gradient: AppColors.secondaryGradient,
                    shelfColor: AppColors.secondaryDark,
                    shelfHeight: 7,
                    radius: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                    child: Text('Enter PIN',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.secondaryDark, fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
              if (isDefaultPin) ...[
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_rounded,
                          color: AppColors.primaryDark, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('First time? Default PIN is 1234',
                                style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.primaryDark,
                                    fontWeight: FontWeight.w800)),
                              const SizedBox(height: 2),
                              Text("Change it once you're in — Savings Hub → Parent PIN.",
                                style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.primaryDark
                                    .withValues(alpha: 0.8 * 255))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showPin(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ParentPinModal(
        title: 'Parent Mode',
        subtitle: 'Enter your PIN to continue',
        onApproved: () {
          Navigator.pop(context);
          onUnlocked();
        },
      ),
    );
  }
}

// ── Parent Dashboard ──────────────────────────────────────────────────────────
class _ParentDashboard extends ConsumerWidget {
  const _ParentDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userStreamProvider).valueOrNull;
    final tasks = ref.watch(tasksStreamProvider).valueOrNull ?? [];
    final reward = ref.watch(activeRewardProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLow,
      body: SafeArea(
        child: Column(
          children: [
            // Header with EXIT
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 20, 0),
              child: Row(
                children: [
                  Text('Parent Mode',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.secondaryDark)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () =>
                        ref.read(_buddyUnlockedProvider.notifier).state = false,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Text('EXIT',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: AppColors.onSurfaceVariant)),
                          const SizedBox(width: 6),
                          const Icon(Icons.logout_rounded,
                            color: AppColors.onSurfaceVariant, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    _BalanceCard(balance: user?.coinBalance ?? 0, taskCount: tasks.length),
                    const SizedBox(height: 16),
                    // Parent-only banner — hides for Pro users automatically
                    const Center(child: AdBanner()),
                    const SizedBox(height: 20),
                    _DashLauncher(
                      icon: Icons.checklist_rounded,
                      iconBg: AppColors.secondaryContainer,
                      iconColor: AppColors.secondaryDark,
                      title: 'Manage Tasks',
                      subtitle: '${tasks.length} task${tasks.length == 1 ? '' : 's'} \u2022 tap to edit',
                      onTap: () => _showSheet(context,
                        child: _ManageTasksSection(tasks: tasks)),
                    ),
                    const SizedBox(height: 12),
                    _DashLauncher(
                      icon: Icons.flag_rounded,
                      iconBg: AppColors.tertiaryContainer,
                      iconColor: AppColors.tertiaryDark,
                      title: 'Reward Goals',
                      subtitle: reward == null
                          ? 'No active goal yet'
                          : 'Active: ${reward.title}',
                      onTap: () => _showSheet(context,
                        child: _RewardSection(reward: reward)),
                    ),
                    const SizedBox(height: 12),
                    const SizedBox(height: 4),
                    _EcosystemSection(pinCode: user?.pinCode ?? '****'),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Slide-up sheet helper ─────────────────────────────────────────────────────
void _showSheet(BuildContext context, {required Widget child}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 4),
              child: Container(
                width: 48, height: 5,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: child,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ── Dashboard launcher row ────────────────────────────────────────────────────
class _DashLauncher extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconColor;
  final String title, subtitle;
  final VoidCallback onTap;

  const _DashLauncher({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChunkyButton(
      onTap: onTap,
      color: AppColors.surfaceContainerLowest,
      shelfColor: AppColors.surfaceContainerHigh,
      shelfHeight: 6,
      radius: 24,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
            color: AppColors.onSurfaceVariant, size: 28),
        ],
      ),
    );
  }
}

// ── Balance Card ──────────────────────────────────────────────────────────────
class _BalanceCard extends ConsumerWidget {
  final int balance;
  final int taskCount;
  const _BalanceCard({required this.balance, required this.taskCount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userStreamProvider).valueOrNull;
    final realValue = user?.formatAmount(balance) ?? '';

    return ChunkyContainer(
      gradient: AppColors.balanceCardGradient,
      shelfColor: const Color(0xFF004A67),
      shelfHeight: 8,
      radius: 32,
      padding: const EdgeInsets.all(24),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CURRENT BALANCE',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white70, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('$balance',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: Colors.white, fontWeight: FontWeight.w800)),
              const SizedBox(width: 12),
              const CurrencySymbol(size: 36, color: AppColors.primary),
            ],
          ),
          if (realValue.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('≈ $realValue',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.85 * 255),
                fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            children: [
              _badge(context, '✓  $taskCount Tasks Available'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18 * 255),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Colors.white, fontWeight: FontWeight.w700)),
    );
  }
}

// ── Manage Tasks Section ──────────────────────────────────────────────────────
class _ManageTasksSection extends ConsumerWidget {
  final List<TaskModel> tasks;
  const _ManageTasksSection({required this.tasks});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Manage Tasks',
                style: Theme.of(context).textTheme.headlineMedium),
            ),
            ChunkyButton(
              onTap: () => _showTaskForm(context, ref),
              gradient: AppColors.primaryGradient,
              shelfColor: AppColors.primaryDark,
              shelfHeight: 5,
              radius: 30,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded, color: AppColors.primaryDark, size: 18),
                  const SizedBox(width: 6),
                  Text('New Task',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.primaryDark)),
                ],
              ),
            ),
          ],
        ),
        Text('Assign chores and set values',
          style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),
        if (tasks.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(child: Text('No tasks yet. Add one!',
              style: Theme.of(context).textTheme.bodyMedium)),
          )
        else
          ...tasks.asMap().entries.map((e) => _TaskRow(task: e.value, index: e.key)),
      ],
    );
  }

  void _showTaskForm(BuildContext context, WidgetRef ref, [TaskModel? existing]) {
    showDialog(
      context: context,
      builder: (_) => _TaskFormDialog(
        existingTask: existing,
        onSave: (task) async {
          final uid = ref.read(currentUidProvider);
          if (uid == null) return;
          if (existing == null) {
            await ref.read(firestoreServiceProvider).addTask(uid, task);
          } else {
            await ref.read(firestoreServiceProvider).updateTask(uid, task);
          }
        },
      ),
    );
  }
}

class _TaskRow extends ConsumerWidget {
  final TaskModel task;
  final int index;
  const _TaskRow({required this.task, required this.index});

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
        color: AppColors.surfaceContainerLowest,
        shelfColor: AppColors.surfaceContainerHigh,
        shelfHeight: 5,
        radius: 20,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(14)),
              child: Icon(Icons.auto_awesome_rounded, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${task.coinReward} COINS',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.primaryDark, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              color: AppColors.onSurfaceVariant,
              onPressed: () => _showEdit(context, ref),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              color: AppColors.danger,
              onPressed: () => _confirmDelete(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  void _showEdit(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _TaskFormDialog(
        existingTask: task,
        onSave: (updated) async {
          final uid = ref.read(currentUidProvider);
          if (uid == null) return;
          await ref.read(firestoreServiceProvider).updateTask(uid, updated);
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Task?'),
        content: Text('Delete "${task.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final uid = ref.read(currentUidProvider);
              if (uid == null) return;
              await ref.read(firestoreServiceProvider).deleteTask(uid, task.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Reward Section ────────────────────────────────────────────────────────────
class _RewardSection extends ConsumerStatefulWidget {
  final RewardModel? reward;
  const _RewardSection({required this.reward});

  @override
  ConsumerState<_RewardSection> createState() => _RewardSectionState();
}

class _RewardSectionState extends ConsumerState<_RewardSection> {
  final _titleCtrl = TextEditingController();
  int _targetCoins = 20;
  String _emoji = '🎁';
  bool _saving = false;
  String? _editingId; // id of goal currently being edited in the form

  final _emojis = ['🎁','🚗','🎮','🍦','⚽','🎨','📚','🦄','🍕','🎪','🌟','🚂'];

  @override
  void initState() {
    super.initState();
    if (widget.reward != null) {
      _titleCtrl.text = widget.reward!.title;
      _targetCoins = widget.reward!.targetCoins;
      _emoji = widget.reward!.emoji;
      _editingId = widget.reward!.id.isEmpty ? null : widget.reward!.id;
    }
  }

  void _loadIntoForm(RewardModel r) {
    setState(() {
      _titleCtrl.text = r.title;
      _targetCoins = r.targetCoins;
      _emoji = r.emoji;
      _editingId = r.id;
    });
  }

  void _resetForm() {
    setState(() {
      _titleCtrl.clear();
      _targetCoins = 20;
      _emoji = '🎁';
      _editingId = null;
    });
  }

  Future<void> _deleteGoal(RewardModel r) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Goal?'),
        content: Text('Delete "${r.title}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    await ref.read(firestoreServiceProvider).deleteReward(uid, r.id);
    if (_editingId == r.id) _resetForm();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rewards = ref.watch(activeRewardsProvider).valueOrNull ?? [];
    final user = ref.watch(userStreamProvider).valueOrNull;
    final isPro = user?.isPremium ?? false;
    final balance = user?.coinBalance ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Reward Goals', style: Theme.of(context).textTheme.headlineMedium),
            if (rewards.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${rewards.length}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w800)),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),

        // Current goals list
        if (rewards.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text('No reward goals yet. Add one below.',
                  style: Theme.of(context).textTheme.bodyMedium),
              ),
            ),
          )
        else
          ...rewards.asMap().entries.map((entry) {
            final r = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _GoalListRow(
                reward: r,
                balance: balance,
                isEditing: _editingId == r.id,
                canDelete: rewards.length > 1 || !isPro,
                onEdit: () => _loadIntoForm(r),
                onDelete: () => _deleteGoal(r),
              ),
            );
          }),

        const SizedBox(height: 8),

        // Form: edit selected or add new
        ChunkyContainer(
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
                  Text(
                    _editingId == null ? 'Add a New Goal' : 'Editing Goal',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  if (_editingId != null)
                    TextButton.icon(
                      onPressed: _resetForm,
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: const Text('New'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Emoji picker
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _emojis.map((e) {
                  final sel = e == _emoji;
                  return GestureDetector(
                    onTap: () => setState(() => _emoji = e),
                    child: Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primaryContainer : AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(child: Text(e,
                        style: const TextStyle(fontSize: 24))),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Reward Title'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                    color: AppColors.danger,
                    onPressed: _targetCoins > 5 ? () => setState(() => _targetCoins -= 5) : null,
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CurrencySymbol(size: 24, color: AppColors.primaryDark),
                          const SizedBox(width: 8),
                          Text('$_targetCoins',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: AppColors.primaryDark)),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    color: AppColors.success,
                    onPressed: _targetCoins < 9999 ? () => setState(() => _targetCoins += 5) : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Save / edit existing primary goal
              SizedBox(
                width: double.infinity,
                child: ChunkyButton(
                  onTap: _saving ? null : () => _save(),
                  disabled: _saving,
                  color: AppColors.tertiaryDark,
                  shelfColor: const Color(0xFF5C1530),
                  shelfHeight: 6,
                  radius: 48,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    _saving
                        ? 'Saving...'
                        : (_editingId == null ? 'Add Goal' : 'Save Changes'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white, letterSpacing: 1),
                  ),
                ),
              ),
              // Pro-only: "Add as New Goal" button
              Consumer(
                builder: (_, ref, __) {
                  final user = ref.watch(userStreamProvider).valueOrNull;
                  if (!(user?.isPremium ?? false)) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: SizedBox(
                      width: double.infinity,
                      child: ChunkyButton(
                        onTap: _saving ? null : () => _save(asNewGoal: true),
                        disabled: _saving,
                        gradient: AppColors.primaryGradient,
                        shelfColor: AppColors.primaryDark,
                        shelfHeight: 5,
                        radius: 48,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_rounded,
                              color: AppColors.primaryDark, size: 18),
                            const SizedBox(width: 6),
                            Text('Add as New Goal',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w800)),
                            const SizedBox(width: 8),
                            Icon(Icons.workspace_premium_rounded,
                              color: AppColors.primaryDark.withValues(alpha: 0.5 * 255),
                              size: 16),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _save({bool asNewGoal = false}) async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final uid = ref.read(currentUidProvider);
    if (uid == null) { setState(() => _saving = false); return; }

    final user = ref.read(userStreamProvider).valueOrNull;
    final isPro = user?.isPremium ?? false;

    // If editing an existing goal → keep its id (update).
    // If adding new (no _editingId) or forced new → empty id (insert).
    final idForSave = asNewGoal ? '' : (_editingId ?? '');
    final reward = RewardModel(
      id: idForSave,
      title: _titleCtrl.text.trim(),
      targetCoins: _targetCoins,
      emoji: _emoji,
    );
    // Pro users can have multiple active goals simultaneously
    await ref.read(firestoreServiceProvider)
        .setReward(uid, reward, allowMultiple: isPro);
    setState(() => _saving = false);
    if (mounted) {
      // Reset form back to "Add" mode after a successful create/update
      _resetForm();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('✅ Reward goal saved!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }
}

// ── Ipon Ecosystem Section ─────────────────────────────────────────────────────
class _EcosystemSection extends ConsumerStatefulWidget {
  final String pinCode;
  const _EcosystemSection({required this.pinCode});

  @override
  ConsumerState<_EcosystemSection> createState() => _EcosystemSectionState();
}

class _EcosystemSectionState extends ConsumerState<_EcosystemSection> {
  final _newPinCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _newPinCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Savings Hub', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        // Pro upgrade / status
        Consumer(
          builder: (_, ref, __) {
            final user = ref.watch(userStreamProvider).valueOrNull;
            final isPro = user?.isPremium ?? false;
            return _ProRow(isPro: isPro);
          },
        ),
        const SizedBox(height: 10),
        // Choose mascot (pig free; bunny & bear Pro)
        Consumer(
          builder: (_, ref, __) {
            final user = ref.watch(userStreamProvider).valueOrNull;
            final kind = mascotKindFromId(user?.mascotKindId);
            return _EcoRow(
              leadingText: kind.emoji,
              iconBg: AppColors.tertiaryContainer,
              iconColor: AppColors.tertiaryDark,
              title: 'Choose Mascot',
              subtitle: 'Currently: ${kind.displayName}',
              onTap: () => showMascotPicker(context),
            );
          },
        ),
        const SizedBox(height: 10),
        // Parent dashboard (Pro only, but visible as locked for free users)
        _EcoRow(
          icon: Icons.analytics_rounded,
          iconBg: AppColors.primaryContainer,
          iconColor: AppColors.primaryDark,
          title: 'Parent Dashboard',
          subtitle: 'Insights, trends & top tasks',
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const DashboardScreen(),
            ));
          },
        ),
        const SizedBox(height: 10),
        _EcoRow(
          icon: Icons.sync_alt_rounded,
          iconBg: AppColors.primaryContainer,
          iconColor: AppColors.primaryDark,
          title: "Child's Name",
          subtitle: 'Update the displayed name',
          onTap: () => _showNameDialog(),
        ),
        const SizedBox(height: 10),
        Consumer(
          builder: (_, ref, __) {
            final pigName = ref.watch(userStreamProvider).valueOrNull?.pigName ?? 'Buddy';
            return _EcoRow(
              icon: Icons.pets_rounded,
              iconBg: AppColors.tertiaryContainer,
              iconColor: AppColors.tertiaryDark,
              title: "Pig's Name",
              subtitle: 'Currently: $pigName',
              onTap: () => _showPigNameDialog(),
            );
          },
        ),
        const SizedBox(height: 10),
        _EcoRow(
          icon: Icons.shield_rounded,
          iconBg: AppColors.secondaryContainer,
          iconColor: AppColors.secondaryDark,
          title: 'Parent PIN',
          subtitle: 'Change your access security code',
          onTap: () => _showPinDialog(),
        ),
        const SizedBox(height: 10),
        Consumer(
          builder: (_, ref, __) {
            final user = ref.watch(userStreamProvider).valueOrNull;
            final symbol = user?.currencySymbol ?? '₱';
            final sub = user == null
                ? 'Set the real-world value of 1 coin'
                : '1 coin = ${user.currencySymbol}${user.coinValue.toStringAsFixed(2)} (${user.currencyCode})';
            return _EcoRow(
              leadingText: symbol,
              iconBg: AppColors.primaryContainer,
              iconColor: AppColors.primaryDark,
              title: 'Coin Values',
              subtitle: sub,
              onTap: () => _showCurrencyDialog(),
            );
          },
        ),
        const SizedBox(height: 10),
        _EcoRow(
          icon: Icons.refresh_rounded,
          iconBg: AppColors.tertiaryContainer,
          iconColor: AppColors.tertiaryDark,
          title: 'Reset Balance',
          subtitle: 'Set coin balance to zero',
          onTap: () => _confirmReset(),
        ),
        const SizedBox(height: 10),
        _EcoRow(
          icon: Icons.star_rounded,
          iconBg: AppColors.primaryContainer,
          iconColor: AppColors.primaryDark,
          title: 'Rate TinySaver Kids',
          subtitle: 'Love it? Leave a quick review ❤',
          onTap: () async {
            await ReviewService.instance.openStoreListing();
          },
        ),
        const SizedBox(height: 10),
        _EcoRow(
          icon: Icons.logout_rounded,
          iconBg: AppColors.surfaceContainerHigh,
          iconColor: AppColors.onSurfaceVariant,
          title: 'Sign Out',
          subtitle: 'Log out of parent account',
          onTap: () async {
            await ref.read(authServiceProvider).signOut();
          },
        ),
      ],
    );
  }

  void _showNameDialog() {
    final user = ref.read(userStreamProvider).valueOrNull;
    _nameCtrl.text = user?.name ?? '';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Child's Name"),
        content: TextField(
          controller: _nameCtrl,
          decoration: const InputDecoration(labelText: 'Name'),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final uid = ref.read(currentUidProvider);
              if (uid == null || _nameCtrl.text.trim().isEmpty) return;
              await ref.read(firestoreServiceProvider).updateUserName(uid, _nameCtrl.text.trim());
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showPinDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Change PIN'),
        content: TextField(
          controller: _newPinCtrl,
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'New 4-digit PIN'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final pin = _newPinCtrl.text.trim();
              if (pin.length != 4 || !RegExp(r'^\d{4}$').hasMatch(pin)) return;
              final uid = ref.read(currentUidProvider);
              if (uid == null) return;
              await ref.read(firestoreServiceProvider).updatePin(uid, pin);
              _newPinCtrl.clear();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showPigNameDialog() {
    final user = ref.read(userStreamProvider).valueOrNull;
    final ctrl = TextEditingController(text: user?.pigName ?? '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Pig's Name"),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Name',
            prefixIcon: Icon(Icons.pets_rounded),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final uid = ref.read(currentUidProvider);
              final name = ctrl.text.trim();
              if (uid == null || name.isEmpty) return;
              await ref.read(firestoreServiceProvider).updatePigName(uid, name);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showCurrencyDialog() {
    showDialog(
      context: context,
      builder: (_) => const _CurrencyPickerDialog(),
    );
  }

  void _confirmReset() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Reset Balance?'),
        content: const Text('This will set the coin balance to 0.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final uid = ref.read(currentUidProvider);
              if (uid == null) return;
              await ref.read(firestoreServiceProvider).resetBalance(uid);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Pro unlock / status row ───────────────────────────────────────────────────
class _ProRow extends StatelessWidget {
  final bool isPro;
  const _ProRow({required this.isPro});

  @override
  Widget build(BuildContext context) {
    if (isPro) {
      return ChunkyContainer(
        gradient: AppColors.primaryGradient,
        shelfColor: AppColors.primaryDark,
        shelfHeight: 5,
        radius: 20,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            const Icon(Icons.workspace_premium_rounded,
              color: AppColors.primaryDark, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TinySaver PRO',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primaryDark, fontWeight: FontWeight.w800)),
                  Text('All features unlocked · Thank you!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.primaryDark.withValues(alpha: 0.75 * 255))),
                ],
              ),
            ),
            const Icon(Icons.check_circle_rounded,
              color: AppColors.primaryDark, size: 22),
          ],
        ),
      );
    }
    return ChunkyButton(
      onTap: () => showPaywall(context),
      color: AppColors.tertiaryContainer,
      shelfColor: AppColors.tertiaryDark,
      shelfHeight: 5,
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppColors.tertiaryDark,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.workspace_premium_rounded,
              color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Unlock Pro',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.tertiaryDark, fontWeight: FontWeight.w800)),
                Text('One-time · Unlock everything',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.tertiaryDark)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded,
            color: AppColors.tertiaryDark, size: 16),
        ],
      ),
    );
  }
}

class _EcoRow extends StatelessWidget {
  final IconData? icon;
  final String? leadingText; // use when leading is a currency symbol like "₱"
  final Color iconBg, iconColor;
  final String title, subtitle;
  final VoidCallback onTap;

  const _EcoRow({
    this.icon,
    this.leadingText,
    required this.iconBg, required this.iconColor,
    required this.title, required this.subtitle, required this.onTap,
  }) : assert(icon != null || leadingText != null,
          'Must provide either an icon or leadingText');

  @override
  Widget build(BuildContext context) {
    return ChunkyButton(
      onTap: onTap,
      color: AppColors.surfaceContainerLowest,
      shelfColor: AppColors.surfaceContainerHigh,
      shelfHeight: 4,
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(14)),
              child: leadingText != null
                  ? Center(
                      child: Text(
                        leadingText!,
                        style: TextStyle(
                          color: iconColor,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    )
                  : Icon(icon!, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
              color: AppColors.outlineVariant, size: 16),
          ],
        ),
    );
  }
}

// ── Task Form Dialog ──────────────────────────────────────────────────────────
class _TaskFormDialog extends StatefulWidget {
  final TaskModel? existingTask;
  final Future<void> Function(TaskModel) onSave;
  const _TaskFormDialog({this.existingTask, required this.onSave});

  @override
  State<_TaskFormDialog> createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends State<_TaskFormDialog> {
  final _titleCtrl = TextEditingController();
  int _coinReward = 1;
  String _iconName = 'star';
  bool _saving = false;

  final _icons = [
    ('star', Icons.star_rounded), ('bed', Icons.bed_rounded),
    ('eco', Icons.eco_rounded), ('menu_book', Icons.menu_book_rounded),
    ('toys', Icons.toys_rounded), ('cleaning_services', Icons.cleaning_services_rounded),
    ('directions_run', Icons.directions_run_rounded), ('brush', Icons.brush_rounded),
    ('favorite', Icons.favorite_rounded),
    ('sentiment_very_satisfied', Icons.sentiment_very_satisfied_rounded),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingTask != null) {
      _titleCtrl.text = widget.existingTask!.title;
      _coinReward = widget.existingTask!.coinReward;
      _iconName = widget.existingTask!.iconName;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Text(widget.existingTask == null ? 'Add Task' : 'Edit Task'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Task Title'),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                    color: AppColors.danger,
                    onPressed: _coinReward > 1 ? () => setState(() => _coinReward--) : null,
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CurrencySymbol(size: 22, color: AppColors.primaryDark),
                          const SizedBox(width: 8),
                          Text('$_coinReward',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: AppColors.primaryDark)),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    color: AppColors.success,
                    onPressed: _coinReward < 99 ? () => setState(() => _coinReward++) : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _icons.map((e) {
                  final sel = e.$1 == _iconName;
                  return GestureDetector(
                    onTap: () => setState(() => _iconName = e.$1),
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primaryContainer : AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(e.$2,
                        color: sel ? AppColors.primaryDark : AppColors.onSurfaceVariant,
                        size: 22),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final task = TaskModel(
      id: widget.existingTask?.id ?? '',
      title: _titleCtrl.text.trim(),
      coinReward: _coinReward,
      iconName: _iconName,
      isActive: true,
      createdAt: widget.existingTask?.createdAt ?? DateTime.now(),
    );
    await widget.onSave(task);
    if (mounted) Navigator.pop(context);
  }
}

// ── Currency Picker Dialog ────────────────────────────────────────────────────

class _CurrencyOption {
  final String code;
  final String symbol;
  final String name;
  final String flag;
  const _CurrencyOption(this.code, this.symbol, this.name, this.flag);
}

const _currencies = [
  _CurrencyOption('PHP', '₱', 'Philippine Peso', '🇵🇭'),
  _CurrencyOption('USD', '\$', 'US Dollar', '🇺🇸'),
  _CurrencyOption('EUR', '€', 'Euro', '🇪🇺'),
  _CurrencyOption('GBP', '£', 'British Pound', '🇬🇧'),
  _CurrencyOption('JPY', '¥', 'Japanese Yen', '🇯🇵'),
  _CurrencyOption('SGD', 'S\$', 'Singapore Dollar', '🇸🇬'),
  _CurrencyOption('AUD', 'A\$', 'Australian Dollar', '🇦🇺'),
  _CurrencyOption('CAD', 'C\$', 'Canadian Dollar', '🇨🇦'),
  _CurrencyOption('INR', '₹', 'Indian Rupee', '🇮🇳'),
  _CurrencyOption('KRW', '₩', 'Korean Won', '🇰🇷'),
];

class _CurrencyPickerDialog extends ConsumerStatefulWidget {
  const _CurrencyPickerDialog();

  @override
  ConsumerState<_CurrencyPickerDialog> createState() =>
      _CurrencyPickerDialogState();
}

class _CurrencyPickerDialogState extends ConsumerState<_CurrencyPickerDialog> {
  late _CurrencyOption _selected;
  final _valueCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(userStreamProvider).valueOrNull;
    _selected = _currencies.firstWhere(
      (c) => c.code == (user?.currencyCode ?? 'PHP'),
      orElse: () => _currencies.first,
    );
    _valueCtrl.text = (user?.coinValue ?? 1.0).toStringAsFixed(2);
  }

  @override
  void dispose() {
    _valueCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value = double.tryParse(_valueCtrl.text.trim());
    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Enter a valid positive value'),
        backgroundColor: AppColors.danger,
      ));
      return;
    }

    setState(() => _saving = true);
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;

    await ref.read(firestoreServiceProvider).updateCurrency(uid,
      code: _selected.code,
      symbol: _selected.symbol,
      coinValue: value,
    );

    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('✅ 1 coin = ${_selected.symbol}${value.toStringAsFixed(2)}'),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final previewCoins = ref.watch(userStreamProvider).valueOrNull?.coinBalance ?? 100;
    final enteredValue = double.tryParse(_valueCtrl.text.trim()) ?? 0;
    final previewTotal = previewCoins * enteredValue;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: AppColors.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(_selected.symbol,
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Coin Values',
                        style: Theme.of(context).textTheme.headlineMedium),
                      Text('Real-world value of 1 coin',
                        style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Currency grid
            Text('Currency',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                letterSpacing: 1.2)),
            const SizedBox(height: 10),
            SizedBox(
              height: 180,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3.2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _currencies.length,
                itemBuilder: (_, i) {
                  final c = _currencies[i];
                  final sel = c.code == _selected.code;
                  return GestureDetector(
                    onTap: () => setState(() => _selected = c),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primaryContainer : AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Text(c.flag, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${c.symbol} ${c.code}',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: sel ? AppColors.primaryDark : AppColors.onSurface,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  )),
                                Text(c.name,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontSize: 11,
                                    color: sel ? AppColors.primaryDark : AppColors.onSurfaceVariant,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (sel)
                            const Icon(Icons.check_circle_rounded,
                              color: AppColors.primaryDark, size: 18),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Value input
            Text('1 coin equals',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                letterSpacing: 1.2)),
            const SizedBox(height: 8),
            TextField(
              controller: _valueCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800, color: AppColors.primaryDark),
              decoration: InputDecoration(
                prefixText: '${_selected.symbol} ',
                prefixStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800, color: AppColors.primaryDark),
                hintText: '1.00',
              ),
            ),
            const SizedBox(height: 14),

            // Preview
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.visibility_rounded,
                    color: AppColors.secondaryDark, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PREVIEW',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.secondaryDark, letterSpacing: 1.2)),
                        Text(
                          '$previewCoins coins = ${_selected.symbol}${previewTotal.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.secondaryDark, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Actions
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _saving ? null : _save,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(48),
                      ),
                      child: Text(
                        _saving ? 'Saving...' : 'Save',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.primaryDark, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Goal list row (parent mode list item) ────────────────────────────────────
class _GoalListRow extends StatelessWidget {
  final RewardModel reward;
  final int balance;
  final bool isEditing;
  final bool canDelete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _GoalListRow({
    required this.reward,
    required this.balance,
    required this.isEditing,
    required this.canDelete,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (balance / reward.targetCoins).clamp(0.0, 1.0);
    final isComplete = balance >= reward.targetCoins;

    return ChunkyContainer(
      color: isEditing
          ? AppColors.primaryContainer
          : AppColors.surfaceContainerLowest,
      shelfColor: isEditing
          ? AppColors.primaryDark
          : AppColors.surfaceContainerHigh,
      shelfHeight: 4,
      radius: 20,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // Emoji chip
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              gradient: isComplete
                  ? AppColors.secondaryGradient
                  : const LinearGradient(colors: [
                      AppColors.surfaceContainer,
                      AppColors.surfaceContainerHigh,
                    ]),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(reward.emoji, style: const TextStyle(fontSize: 26)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reward.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text('$balance / ${reward.targetCoins}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w800)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          backgroundColor:
                              AppColors.surfaceContainerHigh.withValues(alpha: 0.6 * 255),
                          valueColor: AlwaysStoppedAnimation(
                            isComplete
                                ? AppColors.secondaryDark
                                : AppColors.primaryDark),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            color: AppColors.secondaryDark,
            onPressed: onEdit,
            tooltip: 'Edit',
          ),
          if (canDelete)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              color: AppColors.danger,
              onPressed: onDelete,
              tooltip: 'Delete',
            ),
        ],
      ),
    );
  }
}
