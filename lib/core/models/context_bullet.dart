import 'package:flutter/foundation.dart';

@immutable
class ContextBullet {
  final String source;
  final String text;

  const ContextBullet({
    required this.source,
    required this.text,
  });
}
