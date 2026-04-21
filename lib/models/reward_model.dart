import 'package:cloud_firestore/cloud_firestore.dart';

class RewardModel {
  final String id;
  final String title;
  final int targetCoins;
  final String emoji;
  final bool isActive;
  final bool isRedeemed;
  final DateTime? redeemedAt;

  const RewardModel({
    required this.id,
    required this.title,
    required this.targetCoins,
    this.emoji = '🎁',
    this.isActive = true,
    this.isRedeemed = false,
    this.redeemedAt,
  });

  factory RewardModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RewardModel(
      id: doc.id,
      title: data['title'] ?? 'Reward',
      targetCoins: (data['target_coins'] ?? 10).toInt(),
      emoji: data['emoji'] ?? '🎁',
      isActive: data['is_active'] ?? true,
      isRedeemed: data['is_redeemed'] ?? false,
      redeemedAt: (data['redeemed_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'title': title,
    'target_coins': targetCoins,
    'emoji': emoji,
    'is_active': isActive,
    'is_redeemed': isRedeemed,
    if (redeemedAt != null) 'redeemed_at': Timestamp.fromDate(redeemedAt!),
  };

  RewardModel copyWith({
    String? title,
    int? targetCoins,
    String? emoji,
    bool? isActive,
    bool? isRedeemed,
    DateTime? redeemedAt,
  }) =>
      RewardModel(
        id: id,
        title: title ?? this.title,
        targetCoins: targetCoins ?? this.targetCoins,
        emoji: emoji ?? this.emoji,
        isActive: isActive ?? this.isActive,
        isRedeemed: isRedeemed ?? this.isRedeemed,
        redeemedAt: redeemedAt ?? this.redeemedAt,
      );
}
