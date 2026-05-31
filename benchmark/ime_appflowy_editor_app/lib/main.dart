import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(900, 700),
    minimumSize: Size(600, 400),
    title: 'IME Test - appflowy_editor',
    titleBarTopPadding: 0,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const ImeAppFlowyEditorApp());
}

class ImeAppFlowyEditorApp extends StatelessWidget {
  const ImeAppFlowyEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IME Test - appflowy_editor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const ImeEditorPage(),
    );
  }
}

class ImeEditorPage extends StatefulWidget {
  const ImeEditorPage({super.key});

  @override
  State<ImeEditorPage> createState() => _ImeEditorPageState();
}

class _ImeEditorPageState extends State<ImeEditorPage> {
  late EditorState _editorState;

  @override
  void initState() {
    super.initState();
    final document = Document.blank();
    _editorState = EditorState(document: document);
  }

  @override
  void dispose() {
    _editorState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IME Test - appflowy_editor'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Test Chinese IME input below (Sogou Pinyin, Wubi, Microsoft Pinyin)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(16),
                child: AppFlowyEditor(
                  editorState: _editorState,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
