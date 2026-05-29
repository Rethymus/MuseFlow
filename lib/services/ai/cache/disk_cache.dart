import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'ai_cache_entry.dart';
import '../../../utils/logger.dart';
import '../../../utils/file_security_validator.dart';

/// 磁盘缓存实现
/// 持久化缓存到本地存储，提供跨会话缓存能力
class DiskCache {
  final int maxEntries;
  final Duration defaultExpiration;
  final int maxSizeBytes;
  String? _cacheDir;
  int _currentSize = 0;

  DiskCache({
    this.maxEntries = 500,
    this.defaultExpiration = const Duration(days: 7),
    this.maxSizeBytes = 100 * 1024 * 1024, // 100MB
  });

  /// 初始化磁盘缓存
  Future<void> initialize() async {
    if (_cacheDir == null) {
      final appDir = await getApplicationDocumentsDirectory();
      _cacheDir = '${appDir.path}/ai_cache';

      // 使用安全验证器创建安全目录
      final validation = await fileSecurityValidator.validatePath(_cacheDir!);
      if (validation.isValid) {
        await Directory(_cacheDir!).create(recursive: true);
        await _loadMetadata();
      } else {
        throw Exception('缓存目录路径验证失败: ${validation.errorMessage}');
      }
    }
  }

  /// 获取缓存大小
  Future<int> get size async {
    await initialize();
    return await _countEntries();
  }

  /// 获取当前缓存大小（字节）
  Future<int> get currentSize async {
    await initialize();
    return _currentSize;
  }

  /// 获取缓存值
  Future<AICacheEntry?> get(String key) async {
    await initialize();

    try {
      final file = await _getFileForKey(key);
      if (!await file.exists()) {
        return null;
      }

      final json = await file.readAsString();
      final entry = AICacheEntry.fromJson(jsonDecode(json));

      // 检查是否过期
      if (entry.isExpired) {
        await remove(key);
        return null;
      }

      // 更新访问信息
      final updatedEntry = entry.updateAccess();
      await _updateEntry(key, updatedEntry);

      return updatedEntry;
    } catch (e) {
      Logger.error('Error reading disk cache: $e', tag: 'DISK_CACHE', error: e);
      return null;
    }
  }

  /// 设置缓存值
  Future<void> set(String key, AICacheEntry entry) async {
    await initialize();

    try {
      // 检查缓存大小限制
      if (await _wouldExceedMaxSize(entry)) {
        await _evictIfNeeded(entry.content.length);
      }

      // 检查缓存条目限制
      if (await size >= maxEntries) {
        await _evictOldest();
      }

      final file = await _getFileForKey(key);
      final json = jsonEncode(entry.toJson());
      await file.writeAsString(json);
      await _updateSize();
    } catch (e) {
      Logger.error('Error writing disk cache: $e', tag: 'DISK_CACHE', error: e);
    }
  }

  /// 移除缓存条目
  Future<bool> remove(String key) async {
    await initialize();

    try {
      final file = await _getFileForKey(key);
      if (await file.exists()) {
        await file.delete();
        await _updateSize();
        return true;
      }
      return false;
    } catch (e) {
      Logger.error('Error removing disk cache entry: $e',
          tag: 'DISK_CACHE', error: e);
      return false;
    }
  }

  /// 检查缓存是否存在
  Future<bool> contains(String key) async {
    await initialize();

    try {
      final file = await _getFileForKey(key);
      if (!await file.exists()) {
        return false;
      }

      // 读取条目以检查是否过期
      final json = await file.readAsString();
      final entry = AICacheEntry.fromJson(jsonDecode(json));
      return !entry.isExpired;
    } catch (e) {
      return false;
    }
  }

  /// 清空缓存
  Future<void> clear() async {
    await initialize();

    try {
      final cacheDir = Directory(_cacheDir!);
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        await cacheDir.create(recursive: true);
        _currentSize = 0;
      }
    } catch (e) {
      Logger.error('Error clearing disk cache: $e',
          tag: 'DISK_CACHE', error: e);
    }
  }

  /// 移除过期的条目
  Future<List<AICacheEntry>> removeExpired() async {
    await initialize();

    final expired = <AICacheEntry>[];

    try {
      final cacheDir = Directory(_cacheDir!);
      if (!await cacheDir.exists()) return expired;

      await for (final entity in cacheDir.list()) {
        if (entity is File) {
          try {
            final json = await entity.readAsString();
            final entry = AICacheEntry.fromJson(jsonDecode(json));

            if (entry.isExpired) {
              expired.add(entry);
              await entity.delete();
            }
          } catch (e) {
            // 如果文件损坏，删除它
            await entity.delete();
          }
        }
      }

      if (expired.isNotEmpty) {
        await _updateSize();
      }
    } catch (e) {
      Logger.error('Error removing expired entries: $e',
          tag: 'DISK_CACHE', error: e);
    }

    return expired;
  }

  /// 获取所有缓存条目
  Future<List<AICacheEntry>> getAll() async {
    await initialize();

    final entries = <AICacheEntry>[];

    try {
      final cacheDir = Directory(_cacheDir!);
      if (!await cacheDir.exists()) return entries;

      await for (final entity in cacheDir.list()) {
        if (entity is File) {
          try {
            final json = await entity.readAsString();
            final entry = AICacheEntry.fromJson(jsonDecode(json));
            if (!entry.isExpired) {
              entries.add(entry);
            }
          } catch (e) {
            // 跳过损坏的文件
          }
        }
      }
    } catch (e) {
      Logger.error('Error getting all entries: $e',
          tag: 'DISK_CACHE', error: e);
    }

    return entries;
  }

  /// 获取所有键
  Future<List<String>> getKeys() async {
    final entries = await getAll();
    return entries.map((e) => e.cacheKey).toList();
  }

  /// 获取缓存统计信息
  Future<Map<String, dynamic>> getStats() async {
    await initialize();

    final entries = await getAll();
    final totalSize = await currentSize;
    final expired = await removeExpired();

    return {
      'total_entries': entries.length,
      'total_size_bytes': totalSize,
      'max_size_bytes': maxSizeBytes,
      'expired_removed': expired.length,
      'hit_distribution': _getHitDistribution(entries),
      'size_distribution': _getSizeDistribution(entries),
      'age_distribution': _getAgeDistribution(entries),
    };
  }

  /// 获取命中分布
  Map<String, int> _getHitDistribution(List<AICacheEntry> entries) {
    final distribution = <String, int>{
      'never': 0,
      'low': 0,
      'medium': 0,
      'high': 0,
      'very_high': 0,
    };

    for (final entry in entries) {
      final hits = entry.hitCount;
      if (hits == 0) {
        distribution['never'] = distribution['never']! + 1;
      } else if (hits <= 5) {
        distribution['low'] = distribution['low']! + 1;
      } else if (hits <= 20) {
        distribution['medium'] = distribution['medium']! + 1;
      } else if (hits <= 100) {
        distribution['high'] = distribution['high']! + 1;
      } else {
        distribution['very_high'] = distribution['very_high']! + 1;
      }
    }

    return distribution;
  }

  /// 获取大小分布
  Map<String, int> _getSizeDistribution(List<AICacheEntry> entries) {
    final distribution = <String, int>{
      'small': 0,
      'medium': 0,
      'large': 0,
      'huge': 0,
    };

    for (final entry in entries) {
      final size = entry.content.length;
      if (size < 1024) {
        distribution['small'] = distribution['small']! + 1;
      } else if (size < 10240) {
        distribution['medium'] = distribution['medium']! + 1;
      } else if (size < 102400) {
        distribution['large'] = distribution['large']! + 1;
      } else {
        distribution['huge'] = distribution['huge']! + 1;
      }
    }

    return distribution;
  }

  /// 获取年龄分布
  Map<String, int> _getAgeDistribution(List<AICacheEntry> entries) {
    final distribution = <String, int>{
      'fresh': 0, // < 1小时
      'recent': 0, // 1-24小时
      'old': 0, // 1-7天
      'very_old': 0, // > 7天
    };

    final now = DateTime.now();
    for (final entry in entries) {
      final age = now.difference(entry.createdAt);
      if (age < const Duration(hours: 1)) {
        distribution['fresh'] = distribution['fresh']! + 1;
      } else if (age < const Duration(hours: 24)) {
        distribution['recent'] = distribution['recent']! + 1;
      } else if (age < const Duration(days: 7)) {
        distribution['old'] = distribution['old']! + 1;
      } else {
        distribution['very_old'] = distribution['very_old']! + 1;
      }
    }

    return distribution;
  }

  /// 获取缓存键对应的文件
  Future<File> _getFileForKey(String key) async {
    await initialize();

    // 验证缓存目录安全性
    final validation = await fileSecurityValidator.validatePath(_cacheDir!);
    if (!validation.isValid) {
      throw Exception('缓存目录不安全: ${validation.errorMessage}');
    }

    final filename = _hashKey(key);
    final filePath = '$_cacheDir/$filename';

    // 验证文件路径
    final fileValidation = await fileSecurityValidator.validatePath(filePath);
    if (!fileValidation.isValid) {
      throw Exception('缓存文件路径不安全: ${fileValidation.errorMessage}');
    }

    return File(fileValidation.sanitizedPath ?? filePath);
  }

  /// 哈希缓存键
  String _hashKey(String key) {
    // 使用简单的哈希函数
    final bytes = utf8.encode(key);
    final hash = bytes.fold<int>(0, (hash, byte) => hash * 31 + byte);
    return 'cache_$hash';
  }

  /// 计算条目数
  Future<int> _countEntries() async {
    final cacheDir = Directory(_cacheDir!);
    if (!await cacheDir.exists()) return 0;

    int count = 0;
    await for (final entity in cacheDir.list()) {
      if (entity is File) {
        count++;
      }
    }
    return count;
  }

  /// 更新缓存大小
  Future<void> _updateSize() async {
    _currentSize = await _calculateSize();
  }

  /// 计算缓存大小
  Future<int> _calculateSize() async {
    final cacheDir = Directory(_cacheDir!);
    if (!await cacheDir.exists()) return 0;

    int totalSize = 0;
    await for (final entity in cacheDir.list()) {
      if (entity is File) {
        try {
          totalSize += await entity.length();
        } catch (e) {
          // 跳过无法读取的文件
        }
      }
    }
    return totalSize;
  }

  /// 检查是否会超过最大大小
  Future<bool> _wouldExceedMaxSize(AICacheEntry entry) async {
    final curSize = await currentSize;
    final entrySize = entry.content.length + 200; // 内容 + 元数据估算
    return curSize + entrySize > maxSizeBytes;
  }

  /// 需要时驱逐条目
  Future<void> _evictIfNeeded(int requiredSpace) async {
    while ((await currentSize) + requiredSpace > maxSizeBytes) {
      await _evictOldest();
    }
  }

  /// 驱逐最旧的条目
  Future<void> _evictOldest() async {
    final entries = await getAll();
    if (entries.isEmpty) return;

    // 找到最旧的条目
    entries.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final oldest = entries.first;
    await remove(oldest.cacheKey);
  }

  /// 更新条目
  Future<void> _updateEntry(String key, AICacheEntry entry) async {
    final file = await _getFileForKey(key);
    final json = jsonEncode(entry.toJson());
    await file.writeAsString(json);
  }

  /// 加载元数据
  Future<void> _loadMetadata() async {
    try {
      final metadataFile = File('$_cacheDir/.metadata');
      if (await metadataFile.exists()) {
        final json = await metadataFile.readAsString();
        final metadata = jsonDecode(json);
        _currentSize = metadata['current_size'] ?? 0;
      }
    } catch (e) {
      _currentSize = 0;
    }
  }

  /// 保存元数据
  Future<void> _saveMetadata() async {
    try {
      final metadataFile = File('$_cacheDir/.metadata');
      final metadata = {
        'current_size': _currentSize,
        'updated_at': DateTime.now().toIso8601String(),
      };
      await metadataFile.writeAsString(jsonEncode(metadata));
    } catch (e) {
      Logger.error('Error saving metadata: $e', tag: 'DISK_CACHE', error: e);
    }
  }

  /// 清理资源
  Future<void> dispose() async {
    await _saveMetadata();
  }
}
