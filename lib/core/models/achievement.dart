import 'package:flutter/foundation.dart';

@immutable
class Achievement {
  final String id;
  final String title;
  final String description;
  final String iconAsset;
  final DateTime? unlockedAt;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconAsset,
    this.unlockedAt,
  });
}
