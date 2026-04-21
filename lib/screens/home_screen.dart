import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/pig_mascot.dart';
import '../widgets/coin_drop_animation.dart';
import '../widgets/currency_symbol.dart';
import '../widgets/chunky_container.dart';
import '../widgets/parent_pin_modal.dart';
import '../widgets/accessory_shop_sheet.dart';
import '../widgets/add_coin_dialog.dart';
import '../widgets/buddies_teaser.dart';
import '../widgets/speech_bubble.dart';
import '../providers/mascot_greeting.dart';
import '../services/review_service.dart';
import '../services/sound_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late ConfettiController _confettiCtrl;
  bool _showCoinDrop = false;
  final GlobalKey _mascotKey = GlobalKey();

  String? _bubbleMessage;
  int _bubbleNonce = 0; // forces re-animation when same message repeats
  bool _greetedOnOpen = false;

  @override
  void initState() {
    super.initState();
    _confettiCtrl = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    super.dispose();
  }

  void _sayBubble(String text) {
    SoundService.instance.pop();
    setState(() {
      _bubbleMessage = text;
      _bubbleNonce++;
    });
  }

  Future<void> _onAddCoin() async {
    // 1) Ask how many coins
    final amount = await showAddCoinAmountDialog(context);
    if (amount == null || amount <= 0 || !mounted) return;

    // 2) Require parent PIN
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ParentPinModal(
        title: 'Add $amount Coin${amount == 1 ? '' : 's'}',
        subtitle: 'Parent PIN needed to confirm',
        onApproved: () async {
          Navigator.pop(context);
          await _applyCoin(amount);
        },
      ),
    );
  }

  Future<void> _applyCoin(int amount) async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    final user = ref.read(userStreamProvider).valueOrNull;
    if (user == null) return;

    final prevLevel = pigLevelForCoins(user.coinBalance);
    final newBalance = user.coinBalance + amount;
    final newLevel = pigLevelForCoins(newBalance);

    await ref.read(firestoreServiceProvider).addCoins(uid, amount);
    await ref.read(firestoreServiceProvider).recordActivity(uid, user);
    ref.read(pigStateProvider.notifier).setHappy();
    setState(() => _showCoinDrop = true);
    SoundService.instance.coin();
    _sayBubble(MascotGreeting.forCoinAdded(user, amount));

    final didLevelUp = newLevel.index > prevLevel.index;
    ref.read(pigLevelUpProvider.notifier).check(prevLevel, newLevel);
    if (didLevelUp) SoundService.instance.levelUp();

    // Nudge for a Play Store review after enough successful coin-adds
    // (service internally enforces threshold + 30-day cooldown).
    ReviewService.instance.maybePromptAfterCoinAdd();

    final reward = ref.read(activeRewardProvider).valueOrNull;
    final hitGoal = reward != null && newBalance >= reward.targetCoins;
    final crossedMilestone = newBalance ~/ 10 > user.coinBalance ~/ 10;
    if (hitGoal || crossedMilestone) {
      ref.read(pigStateProvider.notifier).setExcited();
      _confettiCtrl.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pigState = ref.watch(pigStateProvider);
    final user = ref.watch(userStreamProvider).valueOrNull;
    final reward = ref.watch(activeRewardProvider).valueOrNull;
    final pigLevel = ref.watch(pigLevelProvider);

    ref.listen(confettiProvider, (_, shouldPlay) {
      if (shouldPlay) _confettiCtrl.play();
    });

    // One-shot greeting on first frame after user is loaded.
    if (!_greetedOnOpen && user != null) {
      _greetedOnOpen = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _sayBubble(MascotGreeting.forAppOpen(user));
      });
    }

    // Celebrate level-ups
    ref.listen<PigLevel?>(pigLevelUpProvider, (_, newLevel) {
      if (newLevel != null) {
        _confettiCtrl.play();
        ref.read(pigStateProvider.notifier).setExcited();
        final u = ref.read(userStreamProvider).valueOrNull;
        if (u != null) _sayBubble(MascotGreeting.forLevelUp(u));
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showLevelUpDialog(newLevel);
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLow,
      body: Stack(
        children: [
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bottomStack = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLevelBadge(pigLevel, user?.coinBalance ?? 0,
                      mascotKindFromId(user?.mascotKindId)),
                    const SizedBox(height: 6),
                    _buildHeadline(pigState, user?.pigName ?? 'Buddy',
                      mascotKindFromId(user?.mascotKindId)),
                    const SizedBox(height: 12),
                    if (user != null) _buildMissionCard(user),
                    const SizedBox(height: 10),
                    const BuddiesTeaser(),
                    const SizedBox(height: 12),
                    _buildAddCoinButton(),
                    const SizedBox(height: 14),
                    _buildQuickNavRow(context, reward, user?.coinBalance ?? 0),
                    const SizedBox(height: 20),
                  ],
                );

                final topBar = _buildTopBar(context, user?.name ?? 'Buddy',
                    user?.coinBalance ?? 0,
                    user?.formatAmount(user.coinBalance),
                    user?.currentStreak ?? 0,
                    user?.isPremium ?? false);

                // Approximate fixed heights for top bar + bottom stack to
                // decide the mascot slot size. If we run out of room,
                // fall back to a scrolling column.
                const approxTopBar = 74.0;
                const approxBottomStack = 530.0; // coarse estimate
                final available = constraints.maxHeight
                    - approxTopBar - approxBottomStack;

                Widget mascotWithBubble(double size) {
                  return Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      PigMascot(
                        key: _mascotKey,
                        pigState: pigState,
                        level: pigLevel,
                        accessoryId: user?.wornAccessory,
                        kind: mascotKindFromId(user?.mascotKindId),
                        size: size,
                      ),
                      if (_bubbleMessage != null)
                        Positioned(
                          top: -8,
                          child: SpeechBubble(
                            key: ValueKey('bubble_$_bubbleNonce'),
                            message: _bubbleMessage!,
                            onDone: () {
                              if (mounted) {
                                setState(() => _bubbleMessage = null);
                              }
                            },
                          ),
                        ),
                    ],
                  );
                }

                if (available >= 220) {
                  // Slot includes generous breathing room above & below;
                  // mascot itself stays much smaller than the slot.
                  final mascotSlot = available.clamp(260.0, 400.0);
                  final mascotSize = (mascotSlot - 140).clamp(140.0, 180.0);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      topBar,
                      const SizedBox(height: 12),
                      SizedBox(
                        height: mascotSlot,
                        child: Center(child: mascotWithBubble(mascotSize)),
                      ),
                      const SizedBox(height: 16),
                      bottomStack,
                    ],
                  );
                }

                // Tight screen: scroll with a compact mascot but still
                // give it some padding above & below.
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      topBar,
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: mascotWithBubble(150)),
                      ),
                      bottomStack,
                    ],
                  ),
                );
              },
            ),
          ),
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiCtrl,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 30,
              gravity: 0.2,
              emissionFrequency: 0.07,
              colors: const [
                AppColors.primary, AppColors.secondary,
                AppColors.tertiary, AppColors.primaryContainer,
              ],
            ),
          ),
          if (_showCoinDrop)
            CoinDropOverlay(
              targetKey: _mascotKey,
              onComplete: () => setState(() => _showCoinDrop = false)),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, String name, int coins,
      String? realValue, int streak, bool isPro) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryContainer,
              border: Border.all(color: AppColors.primaryDark, width: 2),
            ),
            child: const Icon(Icons.savings_rounded, color: AppColors.primaryDark, size: 22),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              'TinySaver Kids',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w800,
                fontSize: 18),
            ),
          ),
          if (isPro) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.workspace_premium_rounded,
                    color: AppColors.primaryDark, size: 12),
                  const SizedBox(width: 2),
                  Text('PRO',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 1)),
                ],
              ),
            ),
          ],
          if (streak > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.tertiaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 3),
                  Text('$streak',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.tertiaryDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 12)),
                ],
              ),
            ),
          ],
          const Spacer(),      // push coin badge to the right edge
          // Coin badge (with optional real value underneath)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$coins', style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primaryDark, fontWeight: FontWeight.w800)),
                    const SizedBox(width: 6),
                    const CurrencySymbol(size: 20, color: AppColors.primaryDark),
                  ],
                ),
              ),
              if (realValue != null && realValue.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2, right: 4),
                  child: Text('≈ $realValue',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.primaryDark.withValues(alpha: 0.75 * 255))),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLevelBadge(PigLevel level, int coins, MascotKind mascotKind) {
    final nextLevel = level.next;
    final minForNext = nextLevel?.minCoins;
    final progress = minForNext == null
        ? 1.0
        : (coins / minForNext).clamp(0.0, 1.0);
    final coinsToGo = minForNext == null ? 0 : (minForNext - coins).clamp(0, minForNext);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Level pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(level.emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  level.displayNameFor(mascotKind).toUpperCase(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Progress bar to next level (or "MAX" pill)
          Expanded(
            child: nextLevel == null
                ? Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    alignment: Alignment.center,
                    child: Text(
                      '✨ MAX LEVEL',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.tertiaryDark,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$coinsToGo to ${nextLevel.displayNameFor(mascotKind)}',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 3),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: AppColors.surfaceContainerHigh,
                          valueColor: const AlwaysStoppedAnimation(
                            AppColors.primaryDark),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _showLevelUpDialog(PigLevel level) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(36),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🎉', style: TextStyle(fontSize: 56,
                color: AppColors.primaryDark)),
              const SizedBox(height: 8),
              Text('LEVEL UP!',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.primaryDark,
                  letterSpacing: 3,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                )),
              const SizedBox(height: 12),
              // Mini preview of new level
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                ),
                child: PigMascot(
                  pigState: PigState.excited,
                  level: level,
                  size: 140,
                ),
              ),
              const SizedBox(height: 16),
              Text(level.displayName,
                style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 6),
              Text(_levelUpDescription(level),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  ref.read(pigLevelUpProvider.notifier).consume();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(48),
                  ),
                  child: Text('Awesome! 🎊',
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

  String _levelUpDescription(PigLevel level) => switch (level) {
    PigLevel.happy => 'Your buddy got a fresh flower accessory!',
    PigLevel.rich  => 'Your buddy now wears a crown and bowtie! 👑',
    PigLevel.baby  => 'Back to the start!',
  };

  Widget _buildHeadline(PigState pigState, String pigName, MascotKind kind) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: Text(
              _getHeadline(pigState, pigName, kind),
              key: ValueKey('$pigState-$pigName-$kind'),
              style: Theme.of(context).textTheme.displayMedium,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getSubtitle(pigState, pigName),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  String _getHeadline(PigState s, String pigName, MascotKind kind) => switch (s) {
    PigState.happy   => 'Yay! ${kind.emoji}',
    PigState.excited => 'Amazing! 🎉',
    PigState.sad     => '$pigName misses you 💛',
    PigState.normal  => 'Hi, $pigName! ${kind.emoji}',
  };

  String _getSubtitle(PigState s, String pigName) => switch (s) {
    PigState.happy   => '$pigName is so proud of you!',
    PigState.excited => 'Woohoo! Keep going, buddy!',
    PigState.sad     => "Let's save together — $pigName is here.",
    PigState.normal  => "Ready for another great day?",
  };

  Widget _buildMissionCard(user) {
    // user is UserModel — check mission state
    if (!user.missionIsForToday) {
      return const SizedBox.shrink();
    }
    final progress = (user.missionProgress / user.missionTarget).clamp(0.0, 1.0);
    final isDone = user.missionComplete;
    final claimed = user.missionClaimed;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ChunkyContainer(
        color: claimed ? AppColors.surfaceContainer : AppColors.surfaceContainerLowest,
        shelfColor: AppColors.surfaceContainerHigh,
        shelfHeight: 5,
        radius: 22,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Text(claimed ? '✅' : (isDone ? '🎁' : '🎯'),
              style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    claimed
                        ? 'Today\'s mission claimed!'
                        : (isDone
                            ? 'Mission complete! Tap to claim.'
                            : "Complete ${user.missionTarget} tasks today"),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: claimed ? AppColors.outline : AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      backgroundColor: AppColors.surfaceContainerHigh,
                      valueColor: AlwaysStoppedAnimation(
                        claimed
                            ? AppColors.outline
                            : (isDone ? AppColors.tertiaryDark : AppColors.primaryDark)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (!claimed)
              GestureDetector(
                onTap: isDone ? _claimMission : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDone
                        ? AppColors.tertiaryContainer
                        : AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isDone ? '+${user.missionBonus} 🎁' : '${user.missionProgress}/${user.missionTarget}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: isDone ? AppColors.tertiaryDark : AppColors.outline,
                      fontWeight: FontWeight.w800),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _claimMission() async {
    final uid = ref.read(currentUidProvider);
    final user = ref.read(userStreamProvider).valueOrNull;
    if (uid == null || user == null) return;
    if (user.missionClaimed || !user.missionComplete) return;
    await ref.read(firestoreServiceProvider)
        .claimMissionBonus(uid, user.missionBonus);
    ref.read(pigStateProvider.notifier).setExcited();
    _confettiCtrl.play();
    SoundService.instance.success();
  }

  Widget _buildAddCoinButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ChunkyButton(
        onTap: _onAddCoin,
        gradient: AppColors.primaryGradient,
        shelfColor: AppColors.primaryDark,
        shelfHeight: 7,
        radius: 48,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryDark,
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Add Coin',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.primaryDark, fontWeight: FontWeight.w800)),
                  Text('SAVINGS',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.primaryDark.withValues(alpha: 0.7 * 255),
                      letterSpacing: 1.2)),
                ],
              ),
            ),
            const CurrencyCoinIcon(size: 36,
              background: AppColors.primaryDark, symbolColor: Colors.white),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickNavRow(BuildContext context, reward, int coins) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _NavCard(
              label: 'Tasks',
              icon: Icons.auto_awesome_rounded,
              color: AppColors.secondaryContainer,
              iconColor: AppColors.secondaryDark,
              onTap: () => ref.read(navIndexProvider.notifier).state = 1,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _NavCard(
              label: 'Shop',
              icon: Icons.shopping_bag_rounded,
              color: AppColors.primaryContainer,
              iconColor: AppColors.primaryDark,
              onTap: _openShop,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _NavCard(
              label: 'Prizes',
              icon: Icons.card_giftcard_rounded,
              color: AppColors.tertiaryContainer,
              iconColor: AppColors.tertiaryDark,
              onTap: () => ref.read(navIndexProvider.notifier).state = 2,
            ),
          ),
        ],
      ),
    );
  }

  void _openShop() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SizedBox(
        height: 600,
        child: AccessoryShopSheet(),
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _NavCard({
    required this.label, required this.icon, required this.color,
    required this.iconColor, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChunkyButton(
      onTap: onTap,
      color: color,
      shelfHeight: 7,
      radius: 32,
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 120,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 40),
            const SizedBox(height: 10),
            Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: iconColor, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

