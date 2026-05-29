import 'package:flutter/foundation.dart';
import '../models/note.dart';
import '../features/knowledge/character_model.dart';
import '../features/knowledge/world_model.dart';

/// 共享数据服务
/// 用于在不同页面间共享数据，实现数据流转和协同工作
class SharedDataService extends ChangeNotifier {
  // 共享的编辑器内容
  String _sharedEditorContent = '';
  Note? _sharedNote;

  // 共享的知识库引用
  CharacterModel? _selectedCharacter;
  WorldModel? _selectedWorld;

  // 上下文锚点数据
  String _contextAnchor = '';

  // 操作历史和状态
  final List<DataOperation> _operationHistory = [];
  int _collaborationMode = 0; // 0: 独立, 1: 只读, 2: 编辑

  // Getters
  String get sharedEditorContent => _sharedEditorContent;
  Note? get sharedNote => _sharedNote;
  CharacterModel? get selectedCharacter => _selectedCharacter;
  WorldModel? get selectedWorld => _selectedWorld;
  String get contextAnchor => _contextAnchor;
  List<DataOperation> get operationHistory =>
      List.unmodifiable(_operationHistory);
  int get collaborationMode => _collaborationMode;

  // 编辑器内容操作
  void updateEditorContent(String content) {
    _sharedEditorContent = content;
    _recordOperation(DataOperationType.editorUpdate, {'content': content});
    notifyListeners();
  }

  void setSharedNote(Note note) {
    _sharedNote = note;
    _sharedEditorContent = note.content;
    _recordOperation(DataOperationType.noteSelect, {'noteId': note.id});
    notifyListeners();
  }

  // 知识库引用操作
  void selectCharacter(CharacterModel character) {
    _selectedCharacter = character;
    _recordOperation(
        DataOperationType.characterSelect, {'characterId': character.id});
    notifyListeners();
  }

  void selectWorld(WorldModel world) {
    _selectedWorld = world;
    _recordOperation(DataOperationType.worldSelect, {'worldId': world.id});
    notifyListeners();
  }

  void clearKnowledgeSelection() {
    _selectedCharacter = null;
    _selectedWorld = null;
    _recordOperation(DataOperationType.selectionClear, {});
    notifyListeners();
  }

  // 上下文锚点操作
  void setContextAnchor(String anchor) {
    _contextAnchor = anchor;
    _recordOperation(DataOperationType.contextAnchorSet, {'anchor': anchor});
    notifyListeners();
  }

  void clearContextAnchor() {
    _contextAnchor = '';
    _recordOperation(DataOperationType.contextAnchorClear, {});
    notifyListeners();
  }

  // 协作模式设置
  void setCollaborationMode(int mode) {
    _collaborationMode = mode;
    _recordOperation(DataOperationType.collaborationModeChange, {'mode': mode});
    notifyListeners();
  }

  // 快速插入操作 - 将知识库内容插入到编辑器
  String insertCharacterReference() {
    if (_selectedCharacter == null) return '';

    final reference = _selectedCharacter!.generateAIPrompt();
    final insertion = '\n[角色参考: ${_selectedCharacter!.name}]\n$reference\n';

    _sharedEditorContent += insertion;
    _recordOperation(DataOperationType.characterInsert,
        {'characterId': _selectedCharacter!.id});
    notifyListeners();

    return insertion;
  }

  String insertWorldReference() {
    if (_selectedWorld == null) return '';

    final reference = _selectedWorld!.generateAIPrompt();
    final insertion = '\n[世界观参考: ${_selectedWorld!.name}]\n$reference\n';

    _sharedEditorContent += insertion;
    _recordOperation(
        DataOperationType.worldInsert, {'worldId': _selectedWorld!.id});
    notifyListeners();

    return insertion;
  }

  // 操作历史管理
  void _recordOperation(DataOperationType type, Map<String, dynamic> data) {
    final operation = DataOperation(
      type: type,
      timestamp: DateTime.now(),
      data: data,
    );

    _operationHistory.add(operation);

    // 限制历史记录大小
    if (_operationHistory.length > 100) {
      _operationHistory.removeAt(0);
    }
  }

  void clearHistory() {
    _operationHistory.clear();
    notifyListeners();
  }

  // 获取最近的操作
  List<DataOperation> getRecentOperations(int count) {
    if (_operationHistory.isEmpty) return [];

    final startIndex = _operationHistory.length - count;
    if (startIndex <= 0) return List.from(_operationHistory);

    return _operationHistory.sublist(startIndex);
  }

  // 检查是否有数据冲突
  bool hasDataConflict() {
    // 检查编辑器内容和笔记是否同步
    if (_sharedNote != null && _sharedNote!.content != _sharedEditorContent) {
      return true;
    }

    return false;
  }

  // 解决数据冲突
  void resolveConflict(bool useEditorContent) {
    if (_sharedNote == null) return;

    if (useEditorContent) {
      _sharedNote = _sharedNote!.copyWith(
        content: _sharedEditorContent,
        updatedAt: DateTime.now(),
      );
    } else {
      _sharedEditorContent = _sharedNote!.content;
    }

    _recordOperation(DataOperationType.conflictResolve, {
      'useEditorContent': useEditorContent,
    });
    notifyListeners();
  }

  // 重置所有共享数据
  void reset() {
    _sharedEditorContent = '';
    _sharedNote = null;
    _selectedCharacter = null;
    _selectedWorld = null;
    _contextAnchor = '';
    _collaborationMode = 0;
    _operationHistory.clear();
    notifyListeners();
  }
}

// 数据操作类型枚举
enum DataOperationType {
  editorUpdate,
  noteSelect,
  characterSelect,
  worldSelect,
  selectionClear,
  contextAnchorSet,
  contextAnchorClear,
  collaborationModeChange,
  characterInsert,
  worldInsert,
  conflictResolve,
}

// 数据操作记录
class DataOperation {
  final DataOperationType type;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  DataOperation({
    required this.type,
    required this.timestamp,
    required this.data,
  });

  @override
  String toString() {
    return 'DataOperation(type: $type, timestamp: $timestamp, data: $data)';
  }
}
