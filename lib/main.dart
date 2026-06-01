import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:super_editor/super_editor.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Configure window manager for desktop
  await WindowManager.instance.ensureInitialized();
  windowManager.waitUntilReadyToShow(
    WindowOptions(
      size: const Size(1200, 800),
      minimumSize: const Size(800, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      title: 'MuseFlow 灵韵',
    ),
    () async {
      await windowManager.show();
      await windowManager.focus();
    },
  );

  runApp(
    const ProviderScope(
      child: MuseFlowApp(),
    ),
  );
}

/// Root application widget for MuseFlow.
class MuseFlowApp extends StatelessWidget {
  const MuseFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MuseFlow 灵韵',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const EditorHomePage(),
    );
  }
}

/// Home page with super_editor integration.
class EditorHomePage extends StatefulWidget {
  const EditorHomePage({super.key});

  @override
  State<EditorHomePage> createState() => _EditorHomePageState();
}

class _EditorHomePageState extends State<EditorHomePage> {
  late final Editor _editor;
  late final MutableDocument _document;
  late final MutableDocumentComposer _composer;

  @override
  void initState() {
    super.initState();
    _document = MutableDocument(
      nodes: [
        ParagraphNode(
          id: Editor.createNodeId(),
          text: AttributedText('开始在 MuseFlow 中创作...'),
        ),
      ],
    );
    _composer = MutableDocumentComposer();
    _editor = createDefaultDocumentEditor(
      document: _document,
      composer: _composer,
    );
  }

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MuseFlow 灵韵'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SuperEditor(
              editor: _editor,
              autofocus: true,
            ),
          ),
        ),
      ),
    );
  }
}
