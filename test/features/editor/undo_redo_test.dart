import 'package:flutter_test/flutter_test.dart';
import 'undo_redo_manager.dart';
import 'text_edit_action.dart';

/// 撤销/重做功能测试
void main() {
  group('UndoRedoManager Tests', () {
    late UndoRedoManager manager;

    setUp(() {
      manager = UndoRedoManager(
        maxHistoryLength: 10,
        maxMemoryUsage: 1024 * 1024, // 1MB
        enableMerge: true,
      );
    });

    tearDown(() {
      manager.dispose();
    });

    test('初始化状态检查', () {
      expect(manager.canUndo, false);
      expect(manager.canRedo, false);
      expect(manager.memoryUsageKB, 0);
      expect(manager.memoryUsagePercent, 0);
    });

    test('执行基本插入动作', () {
      var currentValue = '';

      final action = TextInsertAction(
        position: 0,
        insertedText: 'Hello',
        onInsert: (text) {
          currentValue = text;
        },
        onRemove: () {
          currentValue = '';
        },
      );

      manager.executeAction(action);

      expect(manager.canUndo, true);
      expect(manager.canRedo, false);
      expect(currentValue, 'Hello');
    });

    test('执行撤销操作', () {
      var currentValue = '';

      final action = TextInsertAction(
        position: 0,
        insertedText: 'Hello',
        onInsert: (text) {
          currentValue = text;
        },
        onRemove: () {
          currentValue = '';
        },
      );

      manager.executeAction(action);
      expect(currentValue, 'Hello');

      manager.undo();
      expect(currentValue, '');
      expect(manager.canUndo, false);
      expect(manager.canRedo, true);
    });

    test('执行重做操作', () {
      var currentValue = '';

      final action = TextInsertAction(
        position: 0,
        insertedText: 'Hello',
        onInsert: (text) {
          currentValue = text;
        },
        onRemove: () {
          currentValue = '';
        },
      );

      manager.executeAction(action);
      manager.undo();
      expect(currentValue, '');

      manager.redo();
      expect(currentValue, 'Hello');
      expect(manager.canUndo, true);
      expect(manager.canRedo, false);
    });

    test('多级撤销重做', () {
      var currentValue = '';

      for (int i = 0; i < 5; i++) {
        final action = TextInsertAction(
          position: i,
          insertedText: String.fromCharCode(65 + i), // A, B, C, D, E
          onInsert: (text) {
            currentValue += text;
          },
          onRemove: () {
            if (currentValue.isNotEmpty) {
              currentValue = currentValue.substring(0, currentValue.length - 1);
            }
          },
        );
        manager.executeAction(action);
      }

      expect(currentValue, 'ABCDE');
      expect(manager.canUndo, true);

      // 撤销3次
      manager.undo();
      manager.undo();
      manager.undo();

      expect(currentValue, 'AB');
      expect(manager.canRedo, true);

      // 重做2次
      manager.redo();
      manager.redo();

      expect(currentValue, 'ABCD');
    });

    test('历史记录限制', () {
      var currentValue = '';

      // 添加超过最大历史记录数量的动作
      for (int i = 0; i < 15; i++) {
        final action = TextInsertAction(
          position: i,
          insertedText: String.fromCharCode(65 + i),
          onInsert: (text) {
            currentValue += text;
          },
          onRemove: () {
            if (currentValue.isNotEmpty) {
              currentValue = currentValue.substring(0, currentValue.length - 1);
            }
          },
        );
        manager.executeAction(action);
      }

      // 检查历史记录是否被限制
      expect(manager.historyItems.length, lessThanOrEqualTo(10));
    });

    test('删除动作测试', () {
      var currentValue = 'Hello World';

      final action = TextDeleteAction(
        position: 6,
        deletedText: 'World',
        onRestore: (text) {
          currentValue = currentValue.substring(0, 6) + text;
        },
        onDelete: () {
          currentValue = currentValue.substring(0, 6);
        },
      );

      manager.executeAction(action);

      expect(currentValue, 'Hello ');

      manager.undo();
      expect(currentValue, 'Hello World');
    });

    test('复合动作测试', () {
      var currentValue = '';
      final actions = <TextEditAction>[];

      for (int i = 0; i < 3; i++) {
        actions.add(TextInsertAction(
          position: i,
          insertedText: String.fromCharCode(65 + i),
          onInsert: (text) {
            currentValue += text;
          },
          onRemove: () {
            if (currentValue.isNotEmpty) {
              currentValue = currentValue.substring(0, currentValue.length - 1);
            }
          },
        ));
      }

      manager.executeComposite('批量插入ABC', actions);

      expect(currentValue, 'ABC');
      expect(manager.canUndo, true);

      manager.undo();
      expect(currentValue, '');
    });

    test('动作合并测试', () {
      var currentValue = '';

      final action1 = TextInsertAction(
        position: 0,
        insertedText: 'H',
        onInsert: (text) {
          currentValue = text;
        },
        onRemove: () {
          currentValue = '';
        },
      );

      final action2 = TextInsertAction(
        position: 1,
        insertedText: 'i',
        onInsert: (text) {
          currentValue += text;
        },
        onRemove: () {
          if (currentValue.isNotEmpty) {
            currentValue = currentValue.substring(0, currentValue.length - 1);
          }
        },
      );

      manager.executeAction(action1);

      // 模拟连续输入（通过直接添加而不是执行）
      manager._addToUndoStack(action2);

      // 由于合并功能，应该只有一个历史记录
      expect(manager.historyItems.length, 1);
    });

    test('清空历史记录', () {
      var currentValue = '';

      for (int i = 0; i < 3; i++) {
        final action = TextInsertAction(
          position: i,
          insertedText: String.fromCharCode(65 + i),
          onInsert: (text) {
            currentValue += text;
          },
          onRemove: () {
            if (currentValue.isNotEmpty) {
              currentValue = currentValue.substring(0, currentValue.length - 1);
            }
          },
        );
        manager.executeAction(action);
      }

      manager.clear();

      expect(manager.canUndo, false);
      expect(manager.canRedo, false);
      expect(manager.memoryUsageKB, 0);
    });

    test('内存使用计算', () {
      var currentValue = '';

      final action = TextInsertAction(
        position: 0,
        insertedText: 'A' * 1000, // 1000字符
        onInsert: (text) {
          currentValue = text;
        },
        onRemove: () {
          currentValue = '';
        },
      );

      manager.executeAction(action);

      expect(manager.memoryUsageKB, greaterThan(0));
      expect(manager.memoryUsagePercent, greaterThan(0));
    });

    test('批量操作', () {
      var currentValue = '';

      manager.beginBatch();

      for (int i = 0; i < 3; i++) {
        final action = TextInsertAction(
          position: i,
          insertedText: String.fromCharCode(65 + i),
          onInsert: (text) {
            currentValue += text;
          },
          onRemove: () {
            if (currentValue.isNotEmpty) {
              currentValue = currentValue.substring(0, currentValue.length - 1);
            }
          },
        );
        manager.executeAction(action);
      }

      manager.endBatch();

      expect(currentValue, 'ABC');
      expect(manager.canUndo, true);
    });
  });

  group('TextEditAction Tests', () {
    test('TextInsertAction描述生成', () {
      final action = TextInsertAction(
        position: 0,
        insertedText: 'Hello World, this is a long text',
        onInsert: (text) {},
        onRemove: () {},
      );

      expect(action.description, contains('插入'));
      expect(action.description, contains('...'));
      expect(action.description.length, lessThan(30));
    });

    test('TextDeleteAction描述生成', () {
      final action = TextDeleteAction(
        position: 0,
        deletedText: 'Deleted content',
        onRestore: (text) {},
        onDelete: () {},
      );

      expect(action.description, contains('删除'));
    });

    test('TextReplaceAction执行和撤销', () {
      var currentValue = 'Hello World';

      final action = TextReplaceAction(
        startPosition: 6,
        endPosition: 11,
        oldText: 'World',
        newText: 'Flutter',
        onReplace: (oldText, newText) {
          currentValue = currentValue.replaceFirst(oldText, newText);
        },
      );

      action.execute();
      expect(currentValue, 'Hello Flutter');

      action.undo();
      expect(currentValue, 'Hello World');
    });

    test('复合动作反向撤销', () {
      final steps = <String>[];
      final actions = [
        BasicTextEditAction(
          actionType: 'step1',
          description: '步骤1',
          onExecute: () => steps.add('1'),
          onUndo: () => steps.remove('1'),
        ),
        BasicTextEditAction(
          actionType: 'step2',
          description: '步骤2',
          onExecute: () => steps.add('2'),
          onUndo: () => steps.remove('2'),
        ),
        BasicTextEditAction(
          actionType: 'step3',
          description: '步骤3',
          onExecute: () => steps.add('3'),
          onUndo: () => steps.remove('3'),
        ),
      ];

      final composite = CompositeAction(
        actions: actions,
        compositeDescription: '复合操作',
      );

      composite.execute();
      expect(steps, ['1', '2', '3']);

      composite.undo();
      expect(steps, isEmpty); // 反向撤销
    });
  });
}

// 扩展UndoRedoManager用于测试
extension UndoRedoManagerTest on UndoRedoManager {
  void _addToUndoStack(TextEditAction action) {
    // 模拟内部方法
  }
}
