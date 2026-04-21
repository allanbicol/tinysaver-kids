import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/task_model.dart';
import '../models/task_log_model.dart';
import '../models/reward_model.dart';


class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── User ──────────────────────────────────────────────────────────────────

  Stream<UserModel?> userStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return UserModel.fromFirestore(snap);
    });
  }

  Future<void> updateCoinBalance(String uid, int newBalance) async {
    await _db.collection('users').doc(uid).update({
      'coin_balance': newBalance,
      'last_activity': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addCoins(String uid, int amount) async {
    await _db.collection('users').doc(uid).update({
      'coin_balance': FieldValue.increment(amount),
      'last_activity': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateUserName(String uid, String name) async {
    await _db.collection('users').doc(uid).update({'name': name});
  }

  Future<void> updatePin(String uid, String pin) async {
    await _db.collection('users').doc(uid).update({'pin_code': pin});
  }

  Future<void> updateCurrency(String uid, {
    required String code,
    required String symbol,
    required double coinValue,
  }) async {
    await _db.collection('users').doc(uid).update({
      'currency_code': code,
      'currency_symbol': symbol,
      'coin_value': coinValue,
    });
  }

  Future<void> updatePigName(String uid, String pigName) async {
    await _db.collection('users').doc(uid).update({'pig_name': pigName});
  }

  // ── Streak ──────────────────────────────────────────────────────────────────
  /// Updates the streak based on lastCheckInDate.
  /// Call on any app activity (add coin, complete task, open app).
  Future<void> recordActivity(String uid, UserModel user) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last = user.lastCheckInDate == null
        ? null
        : DateTime(user.lastCheckInDate!.year,
                   user.lastCheckInDate!.month,
                   user.lastCheckInDate!.day);

    int newStreak;
    if (last == null) {
      newStreak = 1;
    } else {
      final diff = today.difference(last).inDays;
      if (diff == 0) return;             // already recorded today
      if (diff == 1) {
        newStreak = user.currentStreak + 1;
      } else {
        newStreak = 1;                   // streak broken
      }
    }
    final longest = newStreak > user.longestStreak ? newStreak : user.longestStreak;
    await _db.collection('users').doc(uid).update({
      'current_streak': newStreak,
      'longest_streak': longest,
      'last_check_in_date': Timestamp.fromDate(today),
      'last_activity': FieldValue.serverTimestamp(),
    });
  }

  // ── Daily Mission ───────────────────────────────────────────────────────────
  /// Generate a new mission if today's mission doesn't exist yet.
  Future<void> ensureDailyMission(String uid, UserModel user) async {
    if (user.missionIsForToday) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    await _db.collection('users').doc(uid).update({
      'mission_date': Timestamp.fromDate(today),
      'mission_target': 3,
      'mission_progress': 0,
      'mission_bonus': 5,
      'mission_claimed': false,
    });
  }

  Future<void> incrementMissionProgress(String uid) async {
    await _db.collection('users').doc(uid).update({
      'mission_progress': FieldValue.increment(1),
    });
  }

  Future<void> claimMissionBonus(String uid, int bonus) async {
    await _db.collection('users').doc(uid).update({
      'mission_claimed': true,
      'coin_balance': FieldValue.increment(bonus),
    });
  }

  // ── Accessories ─────────────────────────────────────────────────────────────
  Future<void> purchaseAccessory(
      String uid, String accessoryId, int price) async {
    await _db.collection('users').doc(uid).update({
      'owned_accessories': FieldValue.arrayUnion([accessoryId]),
      'coin_balance': FieldValue.increment(-price),
    });
  }

  Future<void> setWornAccessory(String uid, String? accessoryId) async {
    await _db.collection('users').doc(uid).update({
      'worn_accessory': accessoryId,
    });
  }

  Future<void> setMascot(String uid, String mascotKindId) async {
    await _db.collection('users').doc(uid).update({
      'mascot_kind': mascotKindId,
    });
  }

  // ── Premium (one-time Pro) ──────────────────────────────────────────────────
  Future<void> grantPremium(String uid) async {
    await _db.collection('users').doc(uid).update({
      'is_premium': true,
      'premium_since': FieldValue.serverTimestamp(),
    });
  }

  /// For debugging / revoking — not exposed in UI.
  Future<void> revokePremium(String uid) async {
    await _db.collection('users').doc(uid).update({
      'is_premium': false,
      'premium_since': null,
    });
  }

  Future<void> resetBalance(String uid) async {
    await _db.collection('users').doc(uid).update({'coin_balance': 0});
  }

  // ── Tasks ─────────────────────────────────────────────────────────────────

  Stream<List<TaskModel>> tasksStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('tasks')
        .where('is_active', isEqualTo: true)
        .snapshots()
        .map((snap) {
          final docs = snap.docs.map(TaskModel.fromFirestore).toList();
          // Sort client-side to avoid needing a composite Firestore index
          docs.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return docs;
        });
  }

  Future<void> addTask(String uid, TaskModel task) async {
    await _db.collection('users').doc(uid).collection('tasks').add(task.toFirestore());
  }

  Future<void> updateTask(String uid, TaskModel task) async {
    await _db.collection('users').doc(uid).collection('tasks').doc(task.id).update(task.toFirestore());
  }

  Future<void> deleteTask(String uid, String taskId) async {
    await _db.collection('users').doc(uid).collection('tasks').doc(taskId).delete();
  }

  // ── Task Logs ─────────────────────────────────────────────────────────────

  Future<void> logTaskCompletion(String uid, TaskModel task) async {
    await _db.collection('users').doc(uid).collection('task_logs').add({
      'task_id': task.id,
      'task_title': task.title,
      'coins_earned': task.coinReward,
      'approved': true,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<TaskLogModel>> recentLogsStream(String uid, {int limit = 10}) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('task_logs')
        .orderBy('created_at', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(TaskLogModel.fromFirestore).toList());
  }

  // ── Rewards ───────────────────────────────────────────────────────────────

  Stream<RewardModel?> activeRewardStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('rewards')
        .where('is_active', isEqualTo: true)
        .where('is_redeemed', isEqualTo: false)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      return RewardModel.fromFirestore(snap.docs.first);
    });
  }

  /// Returns ALL active-unredeemed rewards (used for Pro users).
  Stream<List<RewardModel>> activeRewardsStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('rewards')
        .where('is_active', isEqualTo: true)
        .where('is_redeemed', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.map(RewardModel.fromFirestore).toList());
  }

  /// Upsert a reward.
  /// If [allowMultiple] is false (free tier), deactivates all existing
  /// active rewards first so there's only ever one.
  /// If [allowMultiple] is true (Pro), leaves existing rewards alone.
  Future<void> setReward(String uid, RewardModel reward,
      {bool allowMultiple = false}) async {
    final batch = _db.batch();

    if (!allowMultiple) {
      final existing = await _db
          .collection('users')
          .doc(uid)
          .collection('rewards')
          .where('is_active', isEqualTo: true)
          .where('is_redeemed', isEqualTo: false)
          .get();
      for (final doc in existing.docs) {
        // Don't deactivate the one being updated
        if (doc.id != reward.id) {
          batch.update(doc.reference, {'is_active': false});
        }
      }
    }

    if (reward.id.isEmpty) {
      final ref = _db.collection('users').doc(uid).collection('rewards').doc();
      batch.set(ref, reward.toFirestore());
    } else {
      batch.update(
        _db.collection('users').doc(uid).collection('rewards').doc(reward.id),
        reward.toFirestore(),
      );
    }
    await batch.commit();
  }

  Future<void> deleteReward(String uid, String rewardId) async {
    await _db.collection('users').doc(uid).collection('rewards').doc(rewardId).delete();
  }

  Future<void> redeemReward(String uid, String rewardId) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('rewards')
        .doc(rewardId)
        .update({
          'is_redeemed': true,
          'is_active': false,
          'redeemed_at': FieldValue.serverTimestamp(),
        });
  }

  /// Stream of all redeemed rewards, newest first — used in dashboard report.
  Stream<List<RewardModel>> redeemedRewardsStream(String uid, {int limit = 50}) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('rewards')
        .where('is_redeemed', isEqualTo: true)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(RewardModel.fromFirestore).toList();
          // Sort client-side: newest first (null timestamps go last)
          list.sort((a, b) {
            final ad = a.redeemedAt;
            final bd = b.redeemedAt;
            if (ad == null && bd == null) return 0;
            if (ad == null) return 1;
            if (bd == null) return -1;
            return bd.compareTo(ad);
          });
          if (list.length > limit) return list.sublist(0, limit);
          return list;
        });
  }
}
