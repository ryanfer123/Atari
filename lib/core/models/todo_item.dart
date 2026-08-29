import 'package:flutter/foundation.dart';

@immutable
class TodoItem {
  final String id;
  final String title;
  final String? description;
  final DateTime? deadline;
  final bool isCompleted;
  final DateTime createdAt;

  const TodoItem({
    required this.id,
    required this.title,
    this.description,
    this.deadline,
    required this.isCompleted,
    required this.createdAt,
  });
}
