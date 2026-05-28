import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_state.dart';

class NoteList extends StatelessWidget {
  const NoteList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final notes = appState.notes;

        if (notes.isEmpty) {
          return const Center(
            child: Text(
              'No notes yet\nCreate your first note!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: notes.length,
          itemBuilder: (context, index) {
            final note = notes[index];
            final isSelected = appState.currentNote?.id == note.id;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: isSelected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
              child: ListTile(
                title: Text(
                  note.title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  note.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => appState.selectNote(note),
              ),
            );
          },
        );
      },
    );
  }
}
