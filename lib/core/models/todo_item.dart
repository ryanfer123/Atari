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

  TodoItem copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? deadline,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return TodoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
