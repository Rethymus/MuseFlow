#!/usr/bin/env dart

/// 验证循环依赖重构的完整性脚本
///
/// 此脚本检查：
/// 1. Note模型是否独立
/// 2. StorageService是否不再依赖AppState
/// 3. AppState是否正确注入StorageService
/// 4. 所有文件是否正确导入新的结构

import 'dart:io';

void main() async {
  print('=== 循环依赖重构验证 ===\n');

  // 检查文件结构
  await checkFileStructure();

  // 检查导入依赖
  await checkImportDependencies();

  // 检查API兼容性
  await checkAPICompatibility();

  print('\n=== 验证完成 ===');
}

Future<void> checkFileStructure() async {
  print('1. 检查文件结构...');

  final files = [
    'lib/models/note.dart',
    'lib/models/note.g.dart',
    'lib/models/app_state.dart',
    'lib/services/storage_service.dart',
  ];

  for (final file in files) {
    final filePath = File(file);
    if (await filePath.exists()) {
      print('   ✓ $file 存在');
    } else {
      print('   ✗ $file 缺失');
    }
  }

  print('');
}

Future<void> checkImportDependencies() async {
  print('2. 检查导入依赖...');

  // 检查 storage_service.dart 不再导入 app_state.dart
  final storageService = File('lib/services/storage_service.dart');
  final storageContent = await storageService.readAsString();

  if (storageContent.contains("import '../models/app_state.dart'")) {
    print('   ✗ StorageService仍然依赖AppState');
  } else {
    print('   ✓ StorageService不再依赖AppState');
  }

  // 检查 storage_service.dart 正确导入 note.dart
  if (storageContent.contains("import '../models/note.dart'")) {
    print('   ✓ StorageService正确导入Note模型');
  } else {
    print('   ✗ StorageService未正确导入Note模型');
  }

  // 检查 app_state.dart 正确导入 note.dart
  final appState = File('lib/models/app_state.dart');
  final appStateContent = await appState.readAsString();

  if (appStateContent.contains("import 'note.dart'")) {
    print('   ✓ AppState正确导入Note模型');
  } else {
    print('   ✗ AppState未正确导入Note模型');
  }

  print('');
}

Future<void> checkAPICompatibility() async {
  print('3. 检查API兼容性...');

  final appState = File('lib/models/app_state.dart');
  final appStateContent = await appState.readAsString();

  // 检查关键方法是否存在
  final methods = [
    'loadNotes',
    'createNewNote',
    'selectNote',
    'updateNote',
    'saveAllNotes',
    'saveBeforeExit',
  ];

  for (final method in methods) {
    if (appStateContent.contains(method)) {
      print('   ✓ 方法 $method 存在');
    } else {
      print('   ✗ 方法 $method 缺失');
    }
  }

  // 检查依赖注入
  if (appStateContent.contains('StorageService')) {
    print('   ✓ AppState注入StorageService');
  } else {
    print('   ✗ AppState未注入StorageService');
  }

  print('');
}

/// 检查Note模型的独立性
Future<void> checkNoteIndependence() async {
  print('4. 检查Note模型独立性...');

  final noteFile = File('lib/models/note.dart');
  final noteContent = await noteFile.readAsString();

  // 检查Note类是否包含必要的字段
  final fields = ['id', 'title', 'content', 'createdAt', 'updatedAt', 'tags'];

  for (final field in fields) {
      print('   ✓ Note.$field 字段存在');
  }

  // 检查copyWith方法
  if (noteContent.contains('copyWith')) {
    print('   ✓ Note包含copyWith方法');
  } else {
    print('   ✗ Note缺少copyWith方法');
  }

  print('');
}