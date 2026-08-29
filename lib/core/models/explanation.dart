import 'package:flutter/foundation.dart';
import 'context_bullet.dart';

@immutable
class Explanation {
  final String sentence;
  final List<ContextBullet> contextBullets;
  final DateTime generatedAt;

  const Explanation({
    required this.sentence,
    required this.contextBullets,
    required this.generatedAt,
  });
}
