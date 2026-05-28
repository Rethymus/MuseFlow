/// 撤销/重做系统
///
/// 提供完整的文本编辑撤销/重做功能，支持：
/// - 多级历史记录
/// - 内存优化管理
/// - 动作合并优化
/// - 复合操作
/// - 历史面板显示
///
/// 使用方法：
/// ```dart
/// import 'package:museflow/features/editor/undo_redo/undo_redo.dart';
///
/// final manager = UndoRedoManager();
/// final action = TextInsertAction(...);
/// manager.executeAction(action);
/// manager.undo();
/// manager.redo();
/// ```

export 'undo_redo_manager.dart';
export 'text_edit_action.dart';
export 'history_panel.dart';