import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/models/capture.dart';
import '../../core/services/service_locator.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';

/// Everything circled and saved, newest first.
///
/// Each row shows whether it was embedded — an un-embedded capture is
/// still kept, it just can't be found by meaning, and saying so beats
/// silently returning nothing when it's searched for.
class CapturesTab extends StatefulWidget {
  const CapturesTab({super.key});

  @override
  State<CapturesTab> createState() => _CapturesTabState();
}

class _CapturesTabState extends State<CapturesTab> {
  late final Stream<List<Capture>> _captures = ServiceScope.of(context).captures
      .watchAll();
  final _searchController = TextEditingController();
  List<Capture>? _results;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() => _results = null);
      return;
    }
    final hits = await ServiceScope.of(context).captures.search(query);
    if (mounted) setState(() => _results = hits);
  }

  @override
  Widget build(BuildContext context) {
    final services = ServiceScope.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              hintText: 'Search what you captured',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _results == null
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _results = null);
                      },
                    ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Capture>>(
            stream: _captures,
            builder: (context, snapshot) {
              final all = snapshot.data ?? const <Capture>[];
              final shown = _results ?? all;

              if (all.isEmpty) {
                return const EmptyState(
                  icon: Icons.crop_free,
                  title: 'Nothing captured yet',
                  message: 'Tap Capture, circle something on screen, and it will be saved and searchable here.',
                );
              }
              if (shown.isEmpty) {
                return const EmptyState(
                  icon: Icons.search_off,
                  title: 'No matches',
                  message: 'Nothing captured looks similar to that.',
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 96),
                itemCount: shown.length,
                itemBuilder: (context, i) {
                  final capture = shown[i];
                  return ListTile(
                    leading: SizedBox(
                      width: 48,
                      height: 48,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(capture.imagePath),
                          fit: BoxFit.cover,
                          // The crop lives in the cache dir, so it can be
                          // evicted; the record is still useful without it.
                          errorBuilder: (_, _, _) =>
                              const Icon(Icons.image_not_supported_outlined),
                        ),
                      ),
                    ),
                    title: Text(
                      capture.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      capture.hasEmbedding
                          ? formatWhen(capture.createdAt)
                          : '${formatWhen(capture.createdAt)} · not searchable',
                    ),
                    onTap: () => _showCapture(context, capture),
                    onLongPress: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete capture?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed ?? false) {
                        await services.captures.delete(capture.id);
                      }
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showCapture(BuildContext context, Capture capture) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(capture.imagePath),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
              Gap.m,
              Text(
                formatWhen(capture.createdAt),
                style: Theme.of(context).textTheme.labelMedium,
              ),
              Gap.s,
              Text(capture.text),
            ],
          ),
        ),
      ),
    );
  }
}
