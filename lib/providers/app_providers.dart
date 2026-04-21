import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../models/task_model.dart';
import '../models/reward_model.dart';

// ── Services ──────────────────────────────────────────────────────────────────

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());

// ── Auth State ────────────────────────────────────────────────────────────────

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// ── Current User UID ──────────────────────────────────────────────────────────

final currentUidProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).valueOrNull?.uid;
});

// ── User Data Stream ──────────────────────────────────────────────────────────

final userStreamProvider = StreamProvider<UserModel?>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(null);
  return ref.watch(firestoreServiceProvider).userStream(uid);
});

// ── Tasks Stream ──────────────────────────────────────────────────────────────

final tasksStreamProvider = StreamProvider<List<TaskModel>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).tasksStream(uid);
});

// ── Active Reward Stream ──────────────────────────────────────────────────────

final activeRewardProvider = StreamProvider<RewardModel?>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(null);
  return ref.watch(firestoreServiceProvider).activeRewardStream(uid);
});

/// All active-unredeemed rewards (used for Pro users with multiple goals).
final activeRewardsProvider = StreamProvider<List<RewardModel>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).activeRewardsStream(uid);
});

/// History of redeemed rewards, newest first.
final redeemedRewardsProvider = StreamProvider<List<RewardModel>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).redeemedRewardsStream(uid);
});

// ── Pig Mascot State ──────────────────────────────────────────────────────────

enum PigState { normal, happy, excited, sad }

class PigStateNotifier extends StateNotifier<PigState> {
  PigStateNotifier() : super(PigState.normal);

  void setHappy() {
    state = PigState.happy;
    // Auto-revert to normal after 2.5s
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) state = PigState.normal;
    });
  }

  void setExcited() {
    state = PigState.excited;
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) state = PigState.normal;
    });
  }

  void setSad() => state = PigState.sad;
  void setNormal() => state = PigState.normal;
}

final pigStateProvider = StateNotifierProvider<PigStateNotifier, PigState>(
  (ref) => PigStateNotifier(),
);

// ── Coin Animation Trigger ─────────────────────────────────────────────────────

class CoinAnimationNotifier extends StateNotifier<int> {
  CoinAnimationNotifier() : super(0);

  // Incrementing state value triggers rebuild → animation plays
  void trigger() => state++;
}

final coinAnimationProvider = StateNotifierProvider<CoinAnimationNotifier, int>(
  (ref) => CoinAnimationNotifier(),
);

// ── Confetti Trigger ──────────────────────────────────────────────────────────

class ConfettiNotifier extends StateNotifier<bool> {
  ConfettiNotifier() : super(false);

  void play() {
    state = true;
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) state = false;
    });
  }
}

final confettiProvider = StateNotifierProvider<ConfettiNotifier, bool>(
  (ref) => ConfettiNotifier(),
);

// ── Task Completion (in-session) ──────────────────────────────────────────────

class TaskCompletionNotifier extends StateNotifier<Set<String>> {
  TaskCompletionNotifier() : super({});

  void markDone(String taskId) => state = {...state, taskId};

  bool isDone(String taskId) => state.contains(taskId);

  void reset() => state = {};
}

final taskCompletionProvider =
    StateNotifierProvider<TaskCompletionNotifier, Set<String>>(
  (ref) => TaskCompletionNotifier(),
);

// ── Bottom Nav Index ──────────────────────────────────────────────────────────

final navIndexProvider = StateProvider<int>((ref) => 0);

// ── Mascot kind ───────────────────────────────────────────────────────────────

enum MascotKind {
  pig, bunny, bear, cat, fox, panda, unicorn,
  robot, plant, birdie,
}

extension MascotKindX on MascotKind {
  String get displayName => switch (this) {
    MascotKind.pig     => 'Pinky the Pig',
    MascotKind.bunny   => 'Buni the Bunny',
    MascotKind.bear    => 'Bobo the Bear',
    MascotKind.cat     => 'Kiki the Cat',
    MascotKind.fox     => 'Foxy the Fox',
    MascotKind.panda   => 'Panda the Panda',
    MascotKind.unicorn => 'Stardust the Unicorn',
    MascotKind.robot   => 'Bolt the Robot',
    MascotKind.plant   => 'Sprout the Plant',
    MascotKind.birdie  => 'Tweetie the Birdie',
  };
  String get emoji => switch (this) {
    MascotKind.pig     => '🐷',
    MascotKind.bunny   => '🐰',
    MascotKind.bear    => '🐻',
    MascotKind.cat     => '🐱',
    MascotKind.fox     => '🦊',
    MascotKind.panda   => '🐼',
    MascotKind.unicorn => '🦄',
    MascotKind.robot   => '🤖',
    MascotKind.plant   => '🌱',
    MascotKind.birdie  => '🐦',
  };
  bool get isPremium => this != MascotKind.pig;
  String get id => name;
}

MascotKind mascotKindFromId(String? id) {
  for (final k in MascotKind.values) {
    if (k.name == id) return k;
  }
  return MascotKind.pig;
}

// ── Pig Evolution Level ───────────────────────────────────────────────────────

enum PigLevel { baby, happy, rich }

extension PigLevelX on PigLevel {
  /// Inclusive min coins to reach this level.
  int get minCoins => switch (this) {
    PigLevel.baby  => 0,
    PigLevel.happy => 51,
    PigLevel.rich  => 151,
  };

  /// Exclusive max coins before leveling up (or null for top level).
  int? get maxCoins => switch (this) {
    PigLevel.baby  => 50,
    PigLevel.happy => 150,
    PigLevel.rich  => null,
  };

  /// Neutral fallback name when mascot isn't known.
  String get displayName => switch (this) {
    PigLevel.baby  => 'Baby Saver',
    PigLevel.happy => 'Happy Saver',
    PigLevel.rich  => 'Super Saver',
  };

  /// Mascot-aware name — e.g. "Baby Kitty", "Happy Panda", "Rich Foxy".
  String displayNameFor(MascotKind kind) {
    final nick = switch (kind) {
      MascotKind.pig     => 'Piggy',
      MascotKind.bunny   => 'Bunny',
      MascotKind.bear    => 'Bear',
      MascotKind.cat     => 'Kitty',
      MascotKind.fox     => 'Foxy',
      MascotKind.panda   => 'Panda',
      MascotKind.unicorn => 'Unicorn',
      MascotKind.robot   => 'Bot',
      MascotKind.plant   => 'Sprout',
      MascotKind.birdie  => 'Birdie',
    };
    return switch (this) {
      PigLevel.baby  => 'Baby $nick',
      PigLevel.happy => 'Happy $nick',
      PigLevel.rich  => 'Rich $nick',
    };
  }

  String get emoji => switch (this) {
    PigLevel.baby  => '🍼',
    PigLevel.happy => '🐽',
    PigLevel.rich  => '👑',
  };

  PigLevel? get next => switch (this) {
    PigLevel.baby  => PigLevel.happy,
    PigLevel.happy => PigLevel.rich,
    PigLevel.rich  => null,
  };
}

PigLevel pigLevelForCoins(int coins) {
  if (coins >= 151) return PigLevel.rich;
  if (coins >= 51)  return PigLevel.happy;
  return PigLevel.baby;
}

/// Derived from current user's coin balance.
final pigLevelProvider = Provider<PigLevel>((ref) {
  final coins = ref.watch(userStreamProvider).valueOrNull?.coinBalance ?? 0;
  return pigLevelForCoins(coins);
});

/// Fires once whenever pig levels up — home screen listens and celebrates.
class PigLevelUpNotifier extends StateNotifier<PigLevel?> {
  PigLevelUpNotifier() : super(null);

  /// Call with the previous and new level.
  /// If it's an upgrade, broadcast the new level (non-null triggers celebration).
  void check(PigLevel previous, PigLevel current) {
    if (current.index > previous.index) {
      state = current;
    }
  }

  /// Acknowledge the celebration was shown.
  void consume() => state = null;
}

final pigLevelUpProvider =
    StateNotifierProvider<PigLevelUpNotifier, PigLevel?>(
  (ref) => PigLevelUpNotifier(),
);
