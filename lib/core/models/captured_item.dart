import 'package:flutter/foundation.dart';

enum ItemType { note, todo, healthTarget }

@immutable
class CapturedItem {
  final String rawText;
  final ItemType suggestedType;
  final String suggestedTitle;
  final DateTime? suggestedDeadline;
  final double confidence;

  const CapturedItem({
    required this.rawText,
    required this.suggestedType,
    required this.suggestedTitle,
    this.suggestedDeadline,
    required this.confidence,
  });
}
