import 'package:flutter/foundation.dart';

@immutable
class Note {
  final String id;
  final String text;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Note({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.updatedAt,
  });
}
