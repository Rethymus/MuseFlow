# MuseFlow 反AI味系统集成指南

## 现有集成点

### 1. AI Action Handler 集成
反AI味处理已完全集成到 `/lib/features/editor/ai_action_handler.dart`

```dart
// 在 AIActionHandler 中自动应用
final aiHandler = AIActionHandler(
  onResult: (action, result) {
    // result 已经经过反AI味处理
    print('处理后的自然文本: $result');
  },
  onError: (error) => print('错误: $error'),
  nlConfig: NaturalLanguageConfig.defaultConfig(), // 可自定义配置
);
```

### 2. 编辑器组件集成
可以在 `/lib/features/editor/editor.dart` 中使用：

```dart
class EditorWidget extends StatefulWidget {
  @override
  _EditorWidgetState createState() => _EditorWidgetState();
}

class _EditorWidgetState extends State<EditorWidget> {
  late AIActionHandler _aiHandler;

  @override
  void initState() {
    super.initState();
    _aiHandler = AIActionHandler(
      onResult: _handleAIResult,
      onError: _handleAIError,
    );
  }

  void _handleAIResult(String action, String result) {
    // result 已经是自然化处理的文本
    setState(() {
      _textController.text = result;
    });
  }

  void _handleAIError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('AI处理失败: $error')),
    );
  }

  // 润色按钮
  void _onPolishPressed() {
    final selectedText = _textController.selection.textInside(_textController.text);
    _aiHandler.polish(text: selectedText);
  }

  // 扩写按钮
  void _onExpandPressed() {
    final selectedText = _textController.selection.textInside(_textController.text);
    _aiHandler.expand(text: selectedText);
  }
}
```

### 3. 设置界面集成
在设置页面添加反AI味处理配置选项：

```dart
class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  NaturalLanguageConfig _nlConfig = NaturalLanguageConfig.defaultConfig();
  String _selectedPreset = 'default';

  void _updateConfig(String preset) {
    setState(() {
      _selectedPreset = preset;
      switch (preset) {
        case 'minimal':
          _nlConfig = NaturalLanguageConfig.minimalConfig();
          break;
        case 'aggressive':
          _nlConfig = NaturalLanguageConfig.aggressiveConfig();
          break;
        default:
          _nlConfig = NaturalLanguageConfig.defaultConfig();
      }
    });

    // 更新 AI Handler 配置
    _aiHandler.updateNaturalLanguageConfig(_nlConfig);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          title: Text('反AI味处理强度'),
          subtitle: Text('当前: $_selectedPreset'),
          trailing: DropdownButton<String>(
            value: _selectedPreset,
            items: [
              DropdownMenuItem(value: 'minimal', child: Text('保守')),
              DropdownMenuItem(value: 'default', child: Text('标准')),
              DropdownMenuItem(value: 'aggressive', child: Text('激进')),
            ],
            onChanged: _updateConfig,
          ),
        ),
        SwitchListTile(
          title: Text('保留格式'),
          subtitle: Text('处理时保留原始格式'),
          value: _nlConfig.preserveFormatting,
          onChanged: (value) {
            setState(() {
              _nlConfig = _nlConfig.copyWith(preserveFormatting: value);
            });
            _aiHandler.updateNaturalLanguageConfig(_nlConfig);
          },
        ),
      ],
    );
  }
}
```

## 新功能扩展建议

### 1. 快捷操作面板
```dart
class QuickActionPanel extends StatelessWidget {
  final AIActionHandler aiHandler;
  final String selectedText;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        ElevatedButton(
          onPressed: () => aiHandler.polish(text: selectedText),
          child: Text('🎯 润色'),
        ),
        ElevatedButton(
          onPressed: () => aiHandler.expand(text: selectedText),
          child: Text('📝 扩写'),
        ),
        ElevatedButton(
          onPressed: () => aiHandler.summarize(text: selectedText),
          child: Text('📋 摘要'),
        ),
        // 新增：直接反AI味处理
        ElevatedButton(
          onPressed: () {
            final result = aiHandler.applyNaturalLanguageProcessing(selectedText);
            // 直接应用处理结果
          },
          child: Text('🌿 去除AI味'),
        ),
      ],
    );
  }
}
```

### 2. 实时处理预览
```dart
class LivePreviewWidget extends StatefulWidget {
  final String originalText;

  @override
  _LivePreviewWidgetState createState() => _LivePreviewWidgetState();
}

class _LivePreviewWidgetState extends State<LivePreviewWidget> {
  String _processedText = '';
  ProcessingStatistics? _stats;

  void _updatePreview(String text) {
    final processor = NaturalLanguageProcessor();
    setState(() {
      _processedText = processor.process(text);
      _stats = processor.getStatistics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          onChanged: _updatePreview,
          decoration: InputDecoration(
            labelText: '原始文本',
            hintText: '输入AI生成的文本...',
          ),
        ),
        if (_processedText.isNotEmpty) ...[
          SizedBox(height: 16),
          Text('处理结果:', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(_processedText),
          if (_stats != null) ...[
            SizedBox(height: 8),
            Text('统计: ${_stats!.totalReplacements} 次替换'),
          ],
        ],
      ],
    );
  }
}
```

### 3. 质量检测功能
```dart
class QualityChecker {
  final NaturalLanguageProcessor _processor = NaturalLanguageProcessor();

  Map<String, dynamic> checkQuality(String text) {
    // 先处理获取统计信息
    _processor.process(text);
    final stats = _processor.getStatistics();

    // 计算AI味评分
    final aiFlavorScore = _calculateAIFlavorScore(stats);

    return {
      'ai_flavor_score': aiFlavorScore, // 0-100，越高AI味越重
      'total_replacements': stats.totalReplacements,
      'categories': stats.replacements.keys.toList(),
      'recommendation': _getRecommendation(aiFlavorScore),
    };
  }

  int _calculateAIFlavorScore(ProcessingStatistics stats) {
    // 简单评分算法
    final baseScore = stats.totalReplacements * 10;
    return (baseScore * 0.8).toInt(); // 调整系数
  }

  String _getRecommendation(int score) {
    if (score < 20) return '文本自然，无需处理';
    if (score < 50) return '建议使用最小配置处理';
    if (score < 80) return '建议使用默认配置处理';
    return '强烈建议使用激进配置处理';
  }
}
```

## 数据持久化

### 保存用户配置
```dart
class ConfigStorage {
  static const String _configKey = 'nl_processor_config';

  static Future<void> saveConfig(NaturalLanguageConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    final configJson = {
      'enabledRules': config.enabledRules.toList(),
      'processingIntensity': config.processingIntensity,
      'preserveFormatting': config.preserveFormatting,
      'protectedPhrases': config.protectedPhrases,
    };
    await prefs.setString(_configKey, jsonEncode(configJson));
  }

  static Future<NaturalLanguageConfig?> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final configString = prefs.getString(_configKey);
    if (configString == null) return null;

    final configJson = jsonDecode(configString);
    return NaturalLanguageConfig(
      enabledRules: Set<String>.from(configJson['enabledRules']),
      processingIntensity: configJson['processingIntensity'],
      preserveFormatting: configJson['preserveFormatting'],
      protectedPhrases: List<String>.from(configJson['protectedPhrases']),
    );
  }
}
```

## 性能优化建议

### 1. 异步处理
```dart
class AsyncNaturalLanguageProcessor {
  Future<String> processAsync(String text) async {
    return await compute(_processInBackground, text);
  }

  static String _processInBackground(String text) {
    final processor = NaturalLanguageProcessor();
    return processor.process(text);
  }
}
```

### 2. 缓存机制
```dart
class CachedProcessor {
  final Map<String, String> _cache = {};
  final NaturalLanguageProcessor _processor = NaturalLanguageProcessor();
  final int _maxCacheSize = 100;

  String process(String text) {
    // 检查缓存
    if (_cache.containsKey(text)) {
      return _cache[text]!;
    }

    // 处理文本
    final result = _processor.process(text);

    // 缓存结果
    if (_cache.length < _maxCacheSize) {
      _cache[text] = result;
    }

    return result;
  }

  void clearCache() {
    _cache.clear();
  }
}
```

## 用户反馈收集

### 反馈界面
```dart
class FeedbackWidget extends StatelessWidget {
  final String originalText;
  final String processedText;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('处理效果反馈'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('原始: $originalText'),
          Text('处理后: $processedText'),
          SizedBox(height: 16),
          Text('处理效果如何？'),
          ButtonBar(
            children: [
              TextButton(
                onPressed: () => _submitFeedback('good'),
                child: Text('👍 好'),
              ),
              TextButton(
                onPressed: () => _submitFeedback('neutral'),
                child: Text('😐 一般'),
              ),
              TextButton(
                onPressed: () => _submitFeedback('bad'),
                child: Text('👎 差'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _submitFeedback(String rating) {
    // 发送反馈到服务器
    // 用于优化规则库
  }
}
```

## 总结

反AI味处理系统已完全集成到MuseFlow中，提供了：

1. **无缝集成**: 与AI Action Handler完美配合
2. **灵活配置**: 支持多种预设和自定义配置
3. **用户控制**: 可通过设置界面调整处理强度
4. **性能优化**: 支持异步处理和缓存机制
5. **反馈机制**: 可收集用户反馈持续优化

用户在使用MuseFlow的AI功能时，会自动获得自然、人性化的文本处理结果，无需额外配置，真正实现"人文温度"的产品价值主张。