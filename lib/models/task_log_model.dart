import 'package:cloud_firestore/cloud_firestore.dart';

class TaskLogModel {
  final String id;
  final String taskId;
  final String taskTitle;
  final int coinsEarned;
  final bool approved;
  final DateTime createdAt;

  const TaskLogModel({
    required this.id,
    required this.taskId,
    required this.taskTitle,
    required this.coinsEarned,
    required this.approved,
    required this.createdAt,
  });

  factory TaskLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskLogModel(
      id: doc.id,
      taskId: data['task_id'] ?? '',
      taskTitle: data['task_title'] ?? '',
      coinsEarned: (data['coins_earned'] ?? 0).toInt(),
      approved: data['approved'] ?? false,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'task_id': taskId,
    'task_title': taskTitle,
    'coins_earned': coinsEarned,
    'approved': approved,
    'created_at': Timestamp.fromDate(createdAt),
  };
}
