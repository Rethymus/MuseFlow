import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_state.dart';

class NoteEditor extends StatelessWidget {
  const NoteEditor({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final note = appState.currentNote;

        if (note == null) {
          return const Center(
            child: Text(
              'Select or create a note to start writing',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                initialValue: note.title,
                decoration: const InputDecoration(
                  hintText: 'Note Title',
                  border: OutlineInputBorder(),
                ),
                style: Theme.of(context).textTheme.headlineSmall,
                onChanged: (value) {
                  appState.updateNote(value, note.content);
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TextField(
                  initialValue: note.content,
                  decoration: const InputDecoration(
                    hintText: 'Start writing...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: null,
                  expands: true,
                  onChanged: (value) {
                    appState.updateNote(note.title, value);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
