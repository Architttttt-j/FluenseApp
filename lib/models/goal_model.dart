// lib/models/goal_model.dart

class GoalModel {
  final String id;
  final String mrId;
  final String date;
  final int target;
  final int achieved;
  final String? description;

  GoalModel({
    required this.id,
    required this.mrId,
    required this.date,
    required this.target,
    this.achieved = 0,
    this.description,
  });

  double get progress => target > 0 ? (achieved / target).clamp(0.0, 1.0) : 0;

  factory GoalModel.fromJson(Map<String, dynamic> json) {
    return GoalModel(
      id: json['_id'] ?? json['id'] ?? '',
      mrId: json['mrId'] ?? '',
      date: json['date'] ?? '',
      target: json['target'] ?? 0,
      achieved: json['achieved'] ?? 0,
      description: json['description'],
    );
  }
}
