import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String pigName;            // name the child gave their pig
  final int coinBalance;
  final String pinCode;
  final String currencyCode;
  final String currencySymbol;
  final double coinValue;
  final DateTime? lastActivity;

  // ── Streak ──
  final int currentStreak;         // consecutive days with any activity
  final int longestStreak;
  final DateTime? lastCheckInDate; // date of most recent activity (date-only)

  // ── Daily mission ──
  final DateTime? missionDate;     // date the current mission was generated
  final int missionTarget;         // tasks needed today
  final int missionProgress;       // tasks completed today
  final int missionBonus;          // coins awarded on completion
  final bool missionClaimed;       // user already claimed today's bonus

  // ── Accessories ──
  final List<String> ownedAccessories; // ids of purchased items
  final String? wornAccessory;         // currently equipped id (null = none)

  // ── Mascot selection (Pro: bunny/bear; free: pig) ──
  final String mascotKindId; // e.g. 'pig', 'bunny', 'bear'

  // ── Premium (one-time Pro) ──
  final bool isPremium;
  final DateTime? premiumSince;

  const UserModel({
    required this.id,
    required this.name,
    required this.pigName,
    required this.coinBalance,
    required this.pinCode,
    this.currencyCode = 'PHP',
    this.currencySymbol = '₱',
    this.coinValue = 1.0,
    this.lastActivity,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastCheckInDate,
    this.missionDate,
    this.missionTarget = 3,
    this.missionProgress = 0,
    this.missionBonus = 5,
    this.missionClaimed = false,
    this.ownedAccessories = const [],
    this.wornAccessory,
    this.mascotKindId = 'pig',
    this.isPremium = false,
    this.premiumSince,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] ?? 'My Child',
      pigName: data['pig_name'] ?? 'Buddy',
      coinBalance: (data['coin_balance'] ?? 0).toInt(),
      pinCode: data['pin_code'] ?? '1234',
      currencyCode: data['currency_code'] ?? 'PHP',
      currencySymbol: data['currency_symbol'] ?? '₱',
      coinValue: (data['coin_value'] ?? 1.0).toDouble(),
      lastActivity: (data['last_activity'] as Timestamp?)?.toDate(),
      currentStreak: (data['current_streak'] ?? 0).toInt(),
      longestStreak: (data['longest_streak'] ?? 0).toInt(),
      lastCheckInDate: (data['last_check_in_date'] as Timestamp?)?.toDate(),
      missionDate: (data['mission_date'] as Timestamp?)?.toDate(),
      missionTarget: (data['mission_target'] ?? 3).toInt(),
      missionProgress: (data['mission_progress'] ?? 0).toInt(),
      missionBonus: (data['mission_bonus'] ?? 5).toInt(),
      missionClaimed: data['mission_claimed'] ?? false,
      ownedAccessories: (data['owned_accessories'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      wornAccessory: data['worn_accessory'] as String?,
      mascotKindId: data['mascot_kind'] ?? 'pig',
      isPremium: data['is_premium'] ?? false,
      premiumSince: (data['premium_since'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'pig_name': pigName,
    'coin_balance': coinBalance,
    'pin_code': pinCode,
    'currency_code': currencyCode,
    'currency_symbol': currencySymbol,
    'coin_value': coinValue,
    'last_activity': lastActivity != null ? Timestamp.fromDate(lastActivity!) : null,
    'current_streak': currentStreak,
    'longest_streak': longestStreak,
    'last_check_in_date': lastCheckInDate != null ? Timestamp.fromDate(lastCheckInDate!) : null,
    'mission_date': missionDate != null ? Timestamp.fromDate(missionDate!) : null,
    'mission_target': missionTarget,
    'mission_progress': missionProgress,
    'mission_bonus': missionBonus,
    'mission_claimed': missionClaimed,
    'owned_accessories': ownedAccessories,
    'worn_accessory': wornAccessory,
    'mascot_kind': mascotKindId,
    'is_premium': isPremium,
    'premium_since': premiumSince != null ? Timestamp.fromDate(premiumSince!) : null,
  };

  String formatAmount(int coins) {
    final total = coins * coinValue;
    final whole = total.truncate();
    final decimals = ((total - whole) * 100).round().toString().padLeft(2, '0');
    final wholeStr = whole.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return '$currencySymbol$wholeStr.$decimals';
  }

  /// True if the mission was generated for today.
  bool get missionIsForToday {
    if (missionDate == null) return false;
    final now = DateTime.now();
    return missionDate!.year == now.year &&
        missionDate!.month == now.month &&
        missionDate!.day == now.day;
  }

  bool get missionComplete =>
      missionIsForToday && missionProgress >= missionTarget;

  UserModel copyWith({
    String? name,
    String? pigName,
    int? coinBalance,
    String? pinCode,
    String? currencyCode,
    String? currencySymbol,
    double? coinValue,
    DateTime? lastActivity,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastCheckInDate,
    DateTime? missionDate,
    int? missionTarget,
    int? missionProgress,
    int? missionBonus,
    bool? missionClaimed,
    List<String>? ownedAccessories,
    String? wornAccessory,
    String? mascotKindId,
    bool? isPremium,
    DateTime? premiumSince,
  }) =>
      UserModel(
        id: id,
        name: name ?? this.name,
        pigName: pigName ?? this.pigName,
        coinBalance: coinBalance ?? this.coinBalance,
        pinCode: pinCode ?? this.pinCode,
        currencyCode: currencyCode ?? this.currencyCode,
        currencySymbol: currencySymbol ?? this.currencySymbol,
        coinValue: coinValue ?? this.coinValue,
        lastActivity: lastActivity ?? this.lastActivity,
        currentStreak: currentStreak ?? this.currentStreak,
        longestStreak: longestStreak ?? this.longestStreak,
        lastCheckInDate: lastCheckInDate ?? this.lastCheckInDate,
        missionDate: missionDate ?? this.missionDate,
        missionTarget: missionTarget ?? this.missionTarget,
        missionProgress: missionProgress ?? this.missionProgress,
        missionBonus: missionBonus ?? this.missionBonus,
        missionClaimed: missionClaimed ?? this.missionClaimed,
        ownedAccessories: ownedAccessories ?? this.ownedAccessories,
        wornAccessory: wornAccessory ?? this.wornAccessory,
        mascotKindId: mascotKindId ?? this.mascotKindId,
        isPremium: isPremium ?? this.isPremium,
        premiumSince: premiumSince ?? this.premiumSince,
      );
}
