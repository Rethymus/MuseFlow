import '../utils/logger.dart';
import '../config/app_constants.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/app_state.dart';

/// 延迟加载的存储服务
///
/// 实现渐进式加载策略：
/// - 阶段1：只打开必要的box
/// - 阶段2：加载设置
/// - 阶段3：准备其他功能
class LazyStorageService {
  static final LazyStorageService instance = LazyStorageService._internal();
  LazyStorageService._internal();

  // 存储状态
  bool _isInitialized = false;
  bool _isBasicReady = false;
  bool _isFullReady = false;

  // 存储boxes
  Box<Note>? _notesBox;
  Box<String>? _settingsBox;
  Box<dynamic>? _cacheBox;

  // 完成标志
  final Completer<void> _basicReadyCompleter = Completer<void>();
  final Completer<void> _fullReadyCompleter = Completer<void>();

  /// 基础准备完成Future
  Future<void> get basicReady => _basicReadyCompleter.future;

  /// 完全准备完成Future
  Future<void> get fullReady => _fullReadyCompleter.future;

  /// 是否已基础准备
  bool get isBasicReady => _isBasicReady;

  /// 是否完全准备
  bool get isFullReady => _isFullReady;

  /// 快速初始化 - 仅基础功能
  ///
  /// 这个方法应该在<500ms内完成
  Future<void> quickInitialize() async {
    if (_isBasicReady) return;

    final startTime = DateTime.now();

    try {
      // 注册适配器
      Hive.registerAdapter(NoteAdapter());

      // 只打开设置box（最快）
      _settingsBox = await Hive.openBox<String>('settings');

      // 加载关键设置
      if (!_settingsBox!.containsKey('theme')) {
        await _settingsBox!.put('theme', 'system');
      }

      _isBasicReady = true;
      _basicReadyCompleter.complete();

      final duration = DateTime.now().difference(startTime);
      Logger.debug('存储服务基础初始化完成: ${duration.inMilliseconds}ms');

      if (duration.inMilliseconds > 200) {
        Logger.debug('警告: 存储服务基础初始化超过200ms');
      }
    } catch (e) {
      Logger.debug('存储服务基础初始化失败: $e');
      _basicReadyCompleter.completeError(e);
      rethrow;
    }
  }

  /// 完整初始化 - 所有功能
  ///
  /// 这个方法应该在后台异步执行
  Future<void> fullInitialize() async {
    if (_isFullReady) return;

    // 确保基础初始化完成
    if (!_isBasicReady) {
      await quickInitialize();
    }

    final startTime = DateTime.now();

    try {
      // 打开其他boxes
      _notesBox = await Hive.openBox<Note>('notes');
      _cacheBox = await Hive.openBox('cache');

      // 预加载常用数据（可选）
      await _preloadCommonData();

      _isFullReady = true;
      _fullReadyCompleter.complete();

      final duration = DateTime.now().difference(startTime);
      Logger.debug('存储服务完整初始化完成: ${duration.inMilliseconds}ms');

      if (duration.inMilliseconds > 500) {
        Logger.debug('警告: 存储服务完整初始化超过500ms');
      }
    } catch (e) {
      Logger.debug('存储服务完整初始化失败: $e');
      // 完整初始化失败不应阻止应用启动
      _fullReadyCompleter.complete();
    }
  }

  /// 预加载常用数据
  Future<void> _preloadCommonData() async {
    // 这里可以预加载一些常用数据
    // 例如：最近使用的笔记、常用设置等

    try {
      // 检查是否有最近使用的笔记
      final recentNoteIds = _settingsBox?.get('recent_notes') as String?;
      if (recentNoteIds != null && recentNoteIds.isNotEmpty) {
        // 可以预加载这些笔记
        Logger.debug('发现最近使用的笔记，可以预加载');
      }
    } catch (e) {
      Logger.debug('预加载数据失败: $e');
    }
  }

  /// 获取笔记列表
  Future<List<Note>> getAllNotes() async {
    await fullReady; // 确保完整初始化
    return _notesBox?.values.toList() ?? [];
  }

  /// 保存笔记
  Future<void> saveNote(Note note) async {
    await fullReady;
    await _notesBox?.put(note.id, note);

    // 更新最近使用
    await _updateRecentNotes(note.id);
  }

  /// 删除笔记
  Future<void> deleteNote(String noteId) async {
    await fullReady;
    await _notesBox?.delete(noteId);
  }

  /// 获取设置
  Future<String> getSetting(String key, {String defaultValue = 'system'}) async {
    await basicReady; // 只需要基础初始化
    return _settingsBox?.get(key, defaultValue: defaultValue) ?? defaultValue;
  }

  /// 设置设置
  Future<void> setSetting(String key, String value) async {
    await basicReady;
    await _settingsBox?.put(key, value);
  }

  /// 更新最近使用的笔记
  Future<void> _updateRecentNotes(String noteId) async {
    try {
      final recentNotesJson = await getSetting('recent_notes', defaultValue: '[]');
      final List<String> recentNotes = [];

      // 添加到开头
      recentNotes.add(noteId);

      // 只保留最近10个
      if (recentNotes.length > 10) {
        recentNotes.removeRange(10, recentNotes.length);
      }

      await setSetting('recent_notes', recentNotes.join(','));
    } catch (e) {
      Logger.debug('更新最近笔记失败: $e');
    }
  }

  /// 获取最近使用的笔记
  Future<List<String>> getRecentNotes() async {
    try {
      final recentNotesJson = await getSetting('recent_notes', defaultValue: '');
      if (recentNotesJson.isEmpty) return [];

      return recentNotesJson.split(',');
    } catch (e) {
      return [];
    }
  }

  /// 缓存操作
  Future<void> setCache(String key, dynamic value) async {
    await fullReady;
    await _cacheBox?.put(key, value);
  }

  Future<dynamic> getCache(String key) async {
    await fullReady;
    return _cacheBox?.get(key);
  }

  Future<void> clearCache() async {
    await fullReady;
    await _cacheBox?.clear();
  }

  /// 关闭服务
  Future<void> close() async {
    await Hive.close();
  }
}