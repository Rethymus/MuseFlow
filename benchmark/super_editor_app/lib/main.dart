import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';
import 'package:window_manager/window_manager.dart';

import 'benchmark_runner.dart';

import 'test_text_generator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(1200, 900),
    center: true,
    title: 'super_editor Benchmark',
  );
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
  });

  runApp(const SuperEditorBenchmarkApp());
}

class SuperEditorBenchmarkApp extends StatelessWidget {
  const SuperEditorBenchmarkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'super_editor Benchmark',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const BenchmarkPage(),
    );
  }
}

class BenchmarkPage extends StatefulWidget {
  const BenchmarkPage({super.key});

  @override
  State<BenchmarkPage> createState() => _BenchmarkPageState();
}

class _BenchmarkPageState extends State<BenchmarkPage> {
  late final Editor _editor;
  late final MutableDocument _document;
  final _scrollController = ScrollController();
  late final SuperEditorBenchmarkRunner _runner;

  final _generator = TestTextGenerator(seed: 42);
  BenchmarkResult? _currentResult;
  bool _isRunning = false;
  final _resultLog = <String>[];

  @override
  void initState() {
    super.initState();
    _document = MutableDocument.empty();
    _editor = createDefaultDocumentEditor(
      document: _document,
      composer: MutableDocumentComposer(),
    );
    _runner = SuperEditorBenchmarkRunner(
      editor: _editor,
      scrollController: _scrollController,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _editor.dispose();
    super.dispose();
  }

  Future<void> _loadDocument(BenchmarkSize size) async {
    setState(() => _isRunning = true);
    try {
      final text = _generator.generate(size.charCount);
      _runner.loadText(text);
      setState(() {
        _currentResult = null;
        _resultLog.insert(0, 'Loaded ${size.label} (${size.charCount} chars)');
      });
    } finally {
      setState(() => _isRunning = false);
    }
  }

  Future<void> _runBenchmark(BenchmarkSize size) async {
    setState(() => _isRunning = true);
    try {
      final text = _generator.generate(size.charCount);
      final result = await _runner.runBenchmark(size.charCount, text);
      setState(() {
        _currentResult = result;
        _resultLog.insert(0, _formatResult(result));
      });
    } finally {
      setState(() => _isRunning = false);
    }
  }

  String _formatResult(BenchmarkResult r) => '''
[${r.documentSize} chars] avg=${r.averageFrameTime.toStringAsFixed(2)}ms, p95=${r.p95FrameTime.toStringAsFixed(2)}ms, max=${r.maxFrameTime.toStringAsFixed(2)}ms, jank=${r.jankFrameCount}/${r.totalFrames} frames
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('super_editor Benchmark'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          _buildToolbar(),
          const Divider(height: 1),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: SuperEditor(
                    editor: _editor,
                    scrollController: _scrollController,
                    autofocus: true,
                  ),
                ),
                SizedBox(
                  width: 350,
                  child: _buildResultPanel(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final size in BenchmarkSize.values) ...[
            ElevatedButton(
              onPressed: _isRunning ? null : () => _loadDocument(size),
              child: Text('Load ${size.label}'),
            ),
            FilledButton(
              onPressed: _isRunning ? null : () => _runBenchmark(size),
              child: Text('Benchmark ${size.label}'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultPanel() {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Benchmark Results',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const Divider(height: 1),
          if (_currentResult != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Latest: ${_currentResult!.documentSize} chars',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Avg: ${_currentResult!.averageFrameTime.toStringAsFixed(2)}ms',
                      ),
                      Text(
                        'P95: ${_currentResult!.p95FrameTime.toStringAsFixed(2)}ms',
                      ),
                      Text(
                        'Max: ${_currentResult!.maxFrameTime.toStringAsFixed(2)}ms',
                      ),
                      Text(
                        'Jank: ${_currentResult!.jankFrameCount}/${_currentResult!.totalFrames} frames',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _resultLog.length,
              itemBuilder: (context, index) => ListTile(
                dense: true,
                title: Text(
                  _resultLog[index],
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
