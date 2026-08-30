import 'package:flutter/material.dart';

import '../../core/models/note.dart';
import '../../core/services/service_locator.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';

class NotesTab extends StatefulWidget {
  const NotesTab({super.key});

  @override
  State<NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<NotesTab> {
  late final Stream<List<Note>> _notes = ServiceScope.of(context).notes
      .watchAll();

  @override
  Widget build(BuildContext context) {
    final services = ServiceScope.of(context);

    return Scaffold(
      body: StreamBuilder<List<Note>>(
        stream: _notes,
        builder: (context, snapshot) {
          final notes = snapshot.data ?? const <Note>[];
          if (notes.isEmpty) {
            return EmptyState(
              icon: Icons.sticky_note_2_outlined,
              title: 'No notes yet',
              message: 'Notes give the app context about what matters to you right now.',
              action: FilledButton.icon(
                onPressed: () => _showEditor(context),
                icon: const Icon(Icons.add),
                label: const Text('Write a note'),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: notes.length,
            itemBuilder: (context, i) {
              final note = notes[i];
              return ListTile(
                leading: const Icon(Icons.sticky_note_2_outlined),
                title: Text(
                  note.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(formatWhen(note.createdAt)),
                onTap: () => _showEditor(context, existing: note),
                onLongPress: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete note?'),
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
                  if (confirmed ?? false) await services.notes.delete(note.id);
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'add-note',
        onPressed: () => _showEditor(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showEditor(BuildContext context, {Note? existing}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _NoteEditor(existing: existing),
    );
  }
}

class _NoteEditor extends StatefulWidget {
  const _NoteEditor({this.existing});

  final Note? existing;

  @override
  State<_NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<_NoteEditor> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.existing?.text ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final services = ServiceScope.of(context);
    final navigator = Navigator.of(context);
    final existing = widget.existing;
    if (existing == null) {
      await services.notes.create(text: text);
    } else {
      await services.notes.updateText(existing.id, text);
    }
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing == null ? 'New note' : 'Edit note',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Gap.m,
            TextField(
              controller: _controller,
              autofocus: true,
              maxLines: null,
              minLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Anything worth remembering',
              ),
            ),
            Gap.l,
            FilledButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}
