import 'package:flutter/material.dart';

import '../services/model_services.dart';

/// Small label showing whether a real on-device model or the
/// deterministic placeholder produced a result.
///
/// Shown wherever the app displays model output. The app must never
/// imply a model ran when none did — see
/// `lib/core/services/placeholders/README.md`.
class ModelBackendBadge extends StatelessWidget {
  const ModelBackendBadge({
    super.key,
    required this.backend,
    this.compact = false,
  });

  final ModelBackend backend;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isPlaceholder = backend == ModelBackend.placeholder;
    final label = isPlaceholder ? 'Placeholder' : 'On-device model';
    final icon = isPlaceholder ? Icons.science_outlined : Icons.memory;

    return Tooltip(
      message: isPlaceholder
          ? 'Produced by a deterministic rule, not a model. Add a model in Settings.'
          : 'Produced by an on-device model.',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 8,
          vertical: compact ? 2 : 4,
        ),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: compact ? 11 : 13, color: scheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              label,
              style:
                  (compact
                          ? Theme.of(context).textTheme.labelSmall
                          : Theme.of(context).textTheme.labelMedium)
                      ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
