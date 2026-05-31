import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(900, 700),
    minimumSize: Size(600, 400),
    title: 'IME Test - super_editor',
    titleBarTopPadding: 0,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const ImeSuperEditorApp());
}

class ImeSuperEditorApp extends StatelessWidget {
  const ImeSuperEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IME Test - super_editor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
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
  late MutableDocument _document;
  late MutableDocumentComposer _composer;
  late Editor _editor;
  late CommonEditorOperations _editorOperations;

  @override
  void initState() {
    super.initState();
    _document = MutableDocument.empty();
    _composer = MutableDocumentComposer();
    _editor = Editor(
      document: _document,
      composer: _composer,
    );
    _editorOperations = CommonEditorOperations(
      document: _document,
      composer: _composer,
      editor: _editor,
    );
  }

  @override
  void dispose() {
    _composer.dispose();
    _document.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IME Test - super_editor'),
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
                child: SuperEditor(
                  editor: _editor,
                  document: _document,
                  composer: _composer,
                  editorStyle: EditorStyle.defaultStyle(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
