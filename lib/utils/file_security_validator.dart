import 'dart:convert';
import 'dart:io';
import 'dart:path.dart' as path;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../config/app_constants.dart';
import 'logger.dart';
import 'user_friendly_error_handler.dart';

/// 文件安全验证结果
class FileSecurityResult {
  final bool isValid;
  final String? errorMessage;
  final String? sanitizedPath;

  const FileSecurityResult({
    required this.isValid,
    this.errorMessage,
    this.sanitizedPath,
  });

  factory FileSecurityResult.success([String? sanitizedPath]) {
    return FileSecurityResult(
      isValid: true,
      sanitizedPath: sanitizedPath,
    );
  }

  factory FileSecurityResult.failure(String message) {
    return FileSecurityResult(
      isValid: false,
      errorMessage: message,
    );
  }
}

/// 文件安全审计日志
class SecurityAuditLog {
  final DateTime timestamp;
  final String operation;
  final String? filePath;
  final bool allowed;
  final String? reason;
  final int? fileSize;

  SecurityAuditLog({
    required this.timestamp,
    required this.operation,
    this.filePath,
    required this.allowed,
    this.reason,
    this.fileSize,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'operation': operation,
      'file_path': filePath,
      'allowed': allowed,
      'reason': reason,
      'file_size': fileSize,
    };
  }

  @override
  String toString() {
    return '[${timestamp.toIso8601String()}] $operation: $filePath - '
        'Allowed: $allowed, Reason: $reason, Size: $fileSize';
  }

  factory SecurityAuditLog.fromJson(Map<String, dynamic> json) {
    return SecurityAuditLog(
      timestamp: DateTime.parse(json['timestamp'] as String),
      operation: json['operation'] as String,
      filePath: json['file_path'] as String?,
      allowed: json['allowed'] as bool,
      reason: json['reason'] as String?,
      fileSize: json['file_size'] as int?,
    );
  }
}

/// 文件安全验证器
///
/// 提供完整的文件访问安全控制：
/// - 路径遍历防护
/// - 文件大小限制
/// - 文件类型验证
/// - 权限检查
/// - 沙箱隔离
class FileSecurityValidator {
  // 单例模式
  static FileSecurityValidator? _instance;
  static FileSecurityValidator get instance {
    _instance ??= FileSecurityValidator._internal();
    return _instance!;
  }

  FileSecurityValidator._internal() {
    // 延迟初始化将在第一次使用时执行
  }

  /// 确保安全目录已初始化
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _initializeSafeDirectories();
      _isInitialized = true;
    }
  }

  // 安全配置
  static const int maxSingleFileSize = 10 * 1024 * 1024; // 10MB
  static const int maxTotalSize = 100 * 1024 * 1024; // 100MB
  static const int maxFileNameLength = 255;

  // 允许的文件扩展名白名单
  // 安全修复：移除.js（在黑名单中），添加安全的替代
  static const Set<String> allowedExtensions = {
    '.txt', '.md', '.json', '.csv', '.xml', '.yaml', '.yml',
    '.html', '.css', '.ts', '.dart', '.py', '.java',
    '.pdf', '.png', '.jpg', '.jpeg', '.gif', '.svg', '.webp',
    '.mp3', '.mp4', '.wav', '.m4a', '.mov', '.avi',
    '.zip', '.tar', '.gz', '.7z', '.rar',
    '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx',
  };

  // 禁止的文件扩展名黑名单
  static const Set<String> dangerousExtensions = {
    '.exe',
    '.bat',
    '.cmd',
    '.sh',
    '.ps1',
    '.vbs',
    '.js',
    '.jar',
    '.app',
    '.deb',
    '.rpm',
    '.dmg',
    '.pkg',
    '.msi',
    '.com',
    '.scr',
    '.pif',
    '.vb',
    '.vbe',
    '.jse',
    '.wsf',
    '.wsh',
    '.ws',
    '.scf',
    '.lnk',
    '.iso',
    '.img',
    '.bin',
    '.toast',
    '.dmg',
  };

  // 禁止的文件名模式
  static const List<String> forbiddenFileNamePatterns = [
    r'\.\./', // 父目录遍历
    r'\.\.\\', // Windows父目录遍历
    r'~\$', // Windows临时文件
    r'thumbs\.db', // Windows系统文件
    r'\.ds_store', // macOS系统文件
    r'\._', // macOS资源分叉文件
    r'\.spotlight-', // macOS索引文件
    r'\.trash', // 回收站
    r'\.recycle', // 回收站
  ];

  // 安全目录列表
  final List<String> _safeDirectories = [];
  final List<SecurityAuditLog> _auditLogs = [];
  int _currentSessionSize = 0;
  bool _isInitialized = false;

  /// 初始化安全目录
  Future<void> _initializeSafeDirectories() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      _safeDirectories.add(appDocDir.path);

      final appSupportDir = await getApplicationSupportDirectory();
      _safeDirectories.add(appSupportDir.path);

      final tempDir = await getTemporaryDirectory();
      _safeDirectories.add(tempDir.path);

      // 添加应用特定的安全目录
      final safeSubdirs = [
        '${appDocDir.path}/museflow',
        '${appDocDir.path}/museflow/notes',
        '${appDocDir.path}/museflow/cache',
        '${appDocDir.path}/museflow/exports',
        '${appDocDir.path}/museflow/imports',
        '${appSupportDir.path}/museflow',
      ];

      for (final dir in safeSubdirs) {
        await Directory(dir).create(recursive: true);
        _safeDirectories.add(dir);
      }

      Logger.debug('安全目录初始化完成: $_safeDirectories', tag: 'SECURITY');
    } catch (e) {
      // 使用用户友好的错误处理
      final userError = userFriendlyErrorHandler.handleError(e);
      Logger.error('安全目录初始化失败: ${userError.title}', tag: 'SECURITY');

      // 在实际应用中，应该显示用户友好的错误消息
      // 但在初始化阶段可能没有UI上下文，所以这里只记录
    }
  }

  /// 验证文件路径
  Future<FileSecurityResult> validatePath(
    String filePath, {
    bool requireExistence = false,
    bool checkWritePermission = false,
  }) async {
    try {
      // 检查路径是否为空
      if (filePath.trim().isEmpty) {
        return FileSecurityResult.failure('文件路径不能为空');
      }

      // 规范化路径
      String normalizedPath = path.normalize(filePath);

      // 检查路径遍历攻击
      if (_containsPathTraversal(normalizedPath)) {
        _logAudit('path_validation', filePath, false, '检测到路径遍历攻击');
        return FileSecurityResult.failure('检测到路径遍历攻击');
      }

      // 检查文件名长度
      final fileName = path.basename(normalizedPath);
      if (fileName.length > maxFileNameLength) {
        _logAudit('path_validation', filePath, false, '文件名过长');
        return FileSecurityResult.failure('文件名过长');
      }

      // 检查文件名是否包含禁止模式
      if (_containsForbiddenPattern(fileName)) {
        _logAudit('path_validation', filePath, false, '文件名包含禁止模式');
        return FileSecurityResult.failure('文件名包含禁止模式');
      }

      // 检查文件扩展名
      final extension = path.extension(fileName).toLowerCase();
      if (dangerousExtensions.contains(extension)) {
        _logAudit('path_validation', filePath, false, '危险文件类型');
        return FileSecurityResult.failure('危险文件类型: $extension');
      }

      // 检查是否在安全目录内
      final isInSafeDir = await _isInSafeDirectory(normalizedPath);
      if (!isInSafeDir) {
        _logAudit('path_validation', filePath, false, '不在安全目录内');
        return FileSecurityResult.failure('文件不在安全目录内');
      }

      // 如果需要，检查文件是否存在
      if (requireExistence) {
        final file = File(normalizedPath);
        if (!await file.exists()) {
          _logAudit('path_validation', filePath, false, '文件不存在');
          return FileSecurityResult.failure('文件不存在');
        }
      }

      // 如果需要，检查写入权限
      if (checkWritePermission) {
        final hasPermission = await _checkWritePermission(normalizedPath);
        if (!hasPermission) {
          _logAudit('path_validation', filePath, false, '无写入权限');
          return FileSecurityResult.failure('无写入权限');
        }
      }

      _logAudit('path_validation', normalizedPath, true, null);
      return FileSecurityResult.success(normalizedPath);
    } catch (e) {
      _logAudit('path_validation', filePath, false, '验证异常: $e');
      return FileSecurityResult.failure('路径验证异常: $e');
    }
  }

  /// 验证文件大小
  Future<FileSecurityResult> validateFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return FileSecurityResult.failure('文件不存在');
      }

      final fileSize = await file.length();

      // 检查单个文件大小
      if (fileSize > maxSingleFileSize) {
        _logAudit('size_validation', filePath, false, '文件过大: ${fileSize}bytes');
        return FileSecurityResult.failure(
            '文件过大: ${_formatFileSize(fileSize)} (最大: ${_formatFileSize(maxSingleFileSize)})');
      }

      // 检查会话总大小
      if (_currentSessionSize + fileSize > maxTotalSize) {
        _logAudit('size_validation', filePath, false,
            '会话总大小超限: ${_currentSessionSize + fileSize}');
        return FileSecurityResult.failure(
            '会话总大小超限 (最大: ${_formatFileSize(maxTotalSize)})');
      }

      _logAudit('size_validation', filePath, true, 'Size: $fileSize', fileSize);
      return FileSecurityResult.success(filePath);
    } catch (e) {
      _logAudit('size_validation', filePath, false, '大小检查异常: $e');
      return FileSecurityResult.failure('文件大小检查异常: $e');
    }
  }

  /// 验证文件类型
  FileSecurityResult validateFileType(String filePath) {
    try {
      final extension = path.extension(filePath).toLowerCase();

      // 检查是否在白名单中
      if (!allowedExtensions.contains(extension)) {
        _logAudit('type_validation', filePath, false, '不允许的文件类型');
        return FileSecurityResult.failure('不允许的文件类型: $extension');
      }

      _logAudit('type_validation', filePath, true, '类型: $extension');
      return FileSecurityResult.success(filePath);
    } catch (e) {
      _logAudit('type_validation', filePath, false, '类型检查异常: $e');
      return FileSecurityResult.failure('文件类型检查异常: $e');
    }
  }

  /// 综合安全验证
  Future<FileSecurityResult> validateFile(
    String filePath, {
    bool requireExistence = false,
    bool checkWritePermission = false,
    bool checkType = true,
    bool checkSize = false,
  }) async {
    // 路径验证
    final pathResult = await validatePath(
      filePath,
      requireExistence: requireExistence,
      checkWritePermission: checkWritePermission,
    );
    if (!pathResult.isValid) {
      return pathResult;
    }

    final validatedPath = pathResult.sanitizedPath ?? filePath;

    // 类型验证
    if (checkType) {
      final typeResult = validateFileType(validatedPath);
      if (!typeResult.isValid) {
        return typeResult;
      }
    }

    // 大小验证
    if (checkSize) {
      final sizeResult = await validateFileSize(validatedPath);
      if (!sizeResult.isValid) {
        return sizeResult;
      }
    }

    return FileSecurityResult.success(validatedPath);
  }

  /// 更新会话大小
  void updateSessionSize(int bytes) {
    _currentSessionSize += bytes;
    Logger.debug('当前会话大小: ${_formatFileSize(_currentSessionSize)}',
        tag: 'SECURITY');
  }

  /// 重置会话大小
  void resetSessionSize() {
    _currentSessionSize = 0;
    Logger.debug('会话大小已重置', tag: 'SECURITY');
  }

  /// 创建安全的输出文件路径
  Future<String> createSafeOutputPath(
      String suggestedName, String subDir) async {
    try {
      // 清理文件名
      String safeName = _sanitizeFileName(suggestedName);

      // 确保文件扩展名
      if (!allowedExtensions.contains(path.extension(safeName))) {
        safeName = '$safeName.json';
      }

      // 获取安全目录
      final appDir = await getApplicationDocumentsDirectory();
      final outputDir = Directory('${appDir.path}/museflow/$subDir');

      if (!await outputDir.exists()) {
        await outputDir.create(recursive: true);
      }

      // 生成唯一文件名
      String finalPath = '${outputDir.path}/$safeName';
      int counter = 1;

      while (await File(finalPath).exists()) {
        final nameWithoutExt = path.basenameWithoutExtension(safeName);
        final extension = path.extension(safeName);
        finalPath = '${outputDir.path}/${nameWithoutExt}_$counter$extension';
        counter++;
      }

      // 验证生成的路径
      final result = await validatePath(finalPath);
      if (!result.isValid) {
        throw Exception('无法创建安全的输出路径: ${result.errorMessage}');
      }

      return finalPath;
    } catch (e) {
      throw Exception('创建安全输出路径失败: $e');
    }
  }

  // 私有辅助方法

  bool _containsPathTraversal(String filePath) {
    // 检查原始路径是否包含明确的路径遍历模式
    // 1. 检查是否包含..目录遍历
    if (filePath.contains('..')) {
      // 进一步检查是否真的在尝试向上遍历目录
      final segments = path.split(filePath);
      for (final segment in segments) {
        if (segment == '..') {
          return true; // 发现实际的目录遍历尝试
        }
      }
    }

    // 2. 检查路径分隔符+..的组合（包括Windows风格）
    if (filePath.contains('/../') ||
        filePath.contains('\\..\\') ||
        filePath.startsWith('../') ||
        filePath.startsWith('..\\')) {
      return true;
    }

    // 3. 检查规范化的路径是否仍然包含..
    // 这会捕获经过normalize后仍然存在的路径遍历
    final normalized = path.normalize(filePath);
    final normalizedSegments = path.split(normalized);
    for (final segment in normalizedSegments) {
      if (segment == '..') {
        return true;
      }
    }

    // 如果以上检查都没有发现路径遍历，则认为是安全的
    return false;
  }

  bool _containsForbiddenPattern(String fileName) {
    final lowerName = fileName.toLowerCase();
    for (final pattern in forbiddenFileNamePatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(lowerName)) {
        return true;
      }
    }
    return false;
  }

  Future<bool> _isInSafeDirectory(String filePath) async {
    try {
      // 确保安全目录已初始化
      await _ensureInitialized();

      final absolutePath = path.absolute(filePath);

      for (final safeDir in _safeDirectories) {
        final absoluteSafeDir = path.absolute(safeDir);
        if (path.isWithin(absoluteSafeDir, absolutePath) ||
            path.equals(absoluteSafeDir, path.dirname(absolutePath))) {
          return true;
        }
      }
      return false;
    } catch (e) {
      Logger.error('检查安全目录时出错: $e', tag: 'SECURITY', error: e);
      return false;
    }
  }

  Future<bool> _checkWritePermission(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        // 文件存在，检查是否可写
        final random = DateTime.now().millisecondsSinceEpoch;
        final testFile = File('$filePath.$random.test');
        try {
          await testFile.create();
          await testFile.delete();
          return true;
        } catch (e) {
          return false;
        }
      } else {
        // 文件不存在，检查目录是否可写
        final dir = Directory(path.dirname(filePath));
        if (await dir.exists()) {
          final testFile = File('${dir.path}/.permission_test');
          try {
            await testFile.create();
            await testFile.delete();
            return true;
          } catch (e) {
            return false;
          }
        }
        return false;
      }
    } catch (e) {
      Logger.error('权限检查失败: $e', tag: 'SECURITY', error: e);
      return false;
    }
  }

  String _sanitizeFileName(String fileName) {
    // 移除危险字符
    String sanitized =
        fileName.replaceAll(RegExp(r'[<>:"|?*\\/\x00-\x1f]'), '_');

    // 限制长度
    if (sanitized.length > maxFileNameLength) {
      final ext = path.extension(sanitized);
      final name = path.basenameWithoutExtension(sanitized);
      final maxNameLength = maxFileNameLength - ext.length;
      sanitized = '${name.substring(0, maxNameLength)}$ext';
    }

    return sanitized;
  }

  void _logAudit(
      String operation, String? filePath, bool allowed, String? reason,
      [int? fileSize]) {
    final log = SecurityAuditLog(
      timestamp: DateTime.now(),
      operation: operation,
      filePath: filePath,
      allowed: allowed,
      reason: reason,
      fileSize: fileSize,
    );

    _auditLogs.add(log);
    Logger.debug(log.toString(), tag: 'SECURITY');

    // 限制日志大小
    if (_auditLogs.length > 1000) {
      _auditLogs.removeRange(0, _auditLogs.length - 1000);
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // 公共查询方法

  /// 获取审计日志
  List<SecurityAuditLog> getAuditLogs() {
    return List.unmodifiable(_auditLogs);
  }

  /// 获取最近的审计日志
  List<SecurityAuditLog> getRecentAuditLogs(int count) {
    if (_auditLogs.length <= count) {
      return List.unmodifiable(_auditLogs);
    }
    return List.unmodifiable(_auditLogs.sublist(_auditLogs.length - count));
  }

  /// 获取当前会话大小
  int getCurrentSessionSize() {
    return _currentSessionSize;
  }

  /// 导出审计日志
  Future<String> exportAuditLogs() async {
    final logs = _auditLogs.map((log) => log.toJson()).toList();
    final auditDir = await getApplicationDocumentsDirectory();
    final auditFile = File('${auditDir.path}/museflow/security_audit.json');

    if (!await auditFile.parent.exists()) {
      await auditFile.parent.create(recursive: true);
    }

    final jsonString = const JsonEncoder.withIndent('  ').convert({
      'export_time': DateTime.now().toIso8601String(),
      'total_logs': logs.length,
      'logs': logs,
    });

    await auditFile.writeAsString(jsonString);
    return auditFile.path;
  }

  /// 清理审计日志
  void clearAuditLogs() {
    _auditLogs.clear();
    Logger.debug('审计日志已清理', tag: 'SECURITY');
  }

  /// 获取安全状态
  Map<String, dynamic> getSecurityStatus() {
    final recentLogs = getRecentAuditLogs(50);
    final deniedCount = recentLogs.where((log) => !log.allowed).length;
    final allowedCount = recentLogs.where((log) => log.allowed).length;

    return {
      'current_session_size': _currentSessionSize,
      'current_session_size_formatted': _formatFileSize(_currentSessionSize),
      'max_single_file_size': maxSingleFileSize,
      'max_total_size': maxTotalSize,
      'recent_operations': recentLogs.length,
      'allowed_operations': allowedCount,
      'denied_operations': deniedCount,
      'safe_directories': _safeDirectories,
      'allowed_extensions': allowedExtensions.toList(),
    };
  }

  /// 释放资源
  void dispose() {
    _auditLogs.clear();
    _safeDirectories.clear();
    _currentSessionSize = 0;
  }
}

/// 全局文件安全验证器实例
final fileSecurityValidator = FileSecurityValidator.instance;
