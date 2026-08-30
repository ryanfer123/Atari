import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/model_registry.dart';
import '../../core/services/model_slot_service.dart';
import '../../core/theme/app_theme.dart';

/// Detail screen for one model slot: which model goes here, why, and
/// where to put the file.
class ModelSlotScreen extends StatefulWidget {
  const ModelSlotScreen({super.key, required this.spec, required this.service});

  final ModelSpec spec;
  final ModelSlotService service;

  @override
  State<ModelSlotScreen> createState() => _ModelSlotScreenState();
}

class _ModelSlotScreenState extends State<ModelSlotScreen> {
  final _pathController = TextEditingController();
  ModelSlotStatus? _status;
  String? _modelsDir;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    ModelSlotStatus? status;
    String? dir;
    try {
      status = await widget.service.status(widget.spec.slot);
      dir = await widget.service.modelsDirectory();
    } catch (_) {
      // Channel unavailable (e.g. running on a host without the native
      // side); the screen still renders its guidance.
    }
    if (!mounted) return;
    setState(() {
      _status = status;
      _modelsDir = dir;
      _pathController.text = status?.path ?? '';
      _loading = false;
    });
  }

  String get _suggestedPath {
    final dir = _modelsDir;
    return dir == null
        ? widget.spec.expectedFileName
        : '$dir/${widget.spec.expectedFileName}';
  }

  Future<void> _save() async {
    final path = _pathController.text.trim();
    if (path.isEmpty) return;
    await widget.service.setPath(widget.spec.slot, path);
    await _refresh();
  }

  Future<void> _clear() async {
    await widget.service.clear(widget.spec.slot);
    _pathController.clear();
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final spec = widget.spec;
    final scheme = Theme.of(context).colorScheme;
    final status = _status;

    return Scaffold(
      appBar: AppBar(title: Text(spec.title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          spec.modelName,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Gap.xs,
                        Text(
                          '${spec.format} · ${spec.approxSize}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Gap.m,
                        Text(
                          spec.usedFor,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (spec.note != null) ...[
                          Gap.m,
                          Text(
                            spec.note!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Gap.m,

                _LabelledCard(
                  label: 'Status',
                  child: Row(
                    children: [
                      Icon(
                        status?.isFilled ?? false
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: status?.isFilled ?? false
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                        size: 20,
                      ),
                      Gap.s,
                      Expanded(child: Text(status?.label ?? 'Not added yet')),
                    ],
                  ),
                ),
                Gap.m,

                _LabelledCard(
                  label: 'Where to get it',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        spec.source,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (spec.fallbackModel != null) ...[
                        Gap.s,
                        Text(
                          'Alternative: ${spec.fallbackModel}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ),
                Gap.m,

                _LabelledCard(
                  label: 'How to add it',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Push the file to this device, then paste its path below:',
                      ),
                      Gap.s,
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SelectableText(
                          'adb push ${spec.expectedFileName} $_suggestedPath',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Gap.s,
                      TextButton.icon(
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: _suggestedPath),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Path copied')),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Copy destination path'),
                      ),
                    ],
                  ),
                ),
                Gap.m,

                _LabelledCard(
                  label: 'File path',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _pathController,
                        decoration: InputDecoration(hintText: _suggestedPath),
                        style: const TextStyle(fontSize: 12),
                      ),
                      Gap.s,
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: _save,
                              child: const Text('Save path'),
                            ),
                          ),
                          Gap.s,
                          TextButton(
                            onPressed: _pathController.text.isEmpty
                                ? null
                                : _clear,
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Gap.m,

                Text(
                  'Saving a path records and validates the file. It does not load the model yet — '
                  'the inference runtime is not wired in, so this slot keeps using its placeholder '
                  'until it is.',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
                Gap.xl,
              ],
            ),
    );
  }
}

class _LabelledCard extends StatelessWidget {
  const _LabelledCard({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                letterSpacing: 0.8,
              ),
            ),
            Gap.s,
            child,
          ],
        ),
      ),
    );
  }
}
