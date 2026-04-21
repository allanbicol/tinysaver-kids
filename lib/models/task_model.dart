import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String title;
  final int coinReward;
  final String iconName; // Material icon name as string
  final bool isActive;
  final DateTime createdAt;

  const TaskModel({
    required this.id,
    required this.title,
    required this.coinReward,
    this.iconName = 'star',
    this.isActive = true,
    required this.createdAt,
  });

  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskModel(
      id: doc.id,
      title: data['title'] ?? 'Task',
      coinReward: (data['coin_reward'] ?? 1).toInt(),
      iconName: data['icon_name'] ?? 'star',
      isActive: data['is_active'] ?? true,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'title': title,
    'coin_reward': coinReward,
    'icon_name': iconName,
    'is_active': isActive,
    'created_at': Timestamp.fromDate(createdAt),
  };

  TaskModel copyWith({
    String? title,
    int? coinReward,
    String? iconName,
    bool? isActive,
  }) =>
      TaskModel(
        id: id,
        title: title ?? this.title,
        coinReward: coinReward ?? this.coinReward,
        iconName: iconName ?? this.iconName,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt,
      );
}
