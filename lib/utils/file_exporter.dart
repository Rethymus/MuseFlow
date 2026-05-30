import '../utils/logger.dart';
import '../models/note.dart';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'file_security_validator.dart';

class FileExporter {
  static const String _defaultFileName_ = 'museflow_notes';

  /// 将笔记导出为JSON字符串
  static Future<String> exportToJSON(List<Note> notes) async {
    final List<Map<String, dynamic>> notesJson = notes
        .map((note) => {
              'id': note.id,
              'title': note.title,
              'content': note.content,
              'createdAt': note.createdAt.toIso8601String(),
              'updatedAt': note.updatedAt.toIso8601String(),
              'tags': note.tags,
            })
        .toList();

    return jsonEncode(notesJson);
  }

  /// 安全导出笔记到文件
  ///
  /// 安全特性：
  /// - 路径验证：防止路径遍历攻击
  /// - 文件类型检查：只允许.json文件
  /// - 大小限制：检查文件大小是否在允许范围内
  /// - 权限检查：验证写入权限
  /// - 沙箱隔离：使用安全的工作目录
  static Future<bool> exportToFile(List<Note> notes) async {
    try {
      // 1. 生成JSON内容
      final jsonString = await exportToJSON(notes);

      // 2. 检查内容大小
      final contentSize = jsonString.length;
      if (contentSize > FileSecurityValidator.maxSingleFileSize) {
        Logger.debug('导出失败：内容过大 (${contentSize} bytes)');
        return false;
      }

      // 3. 创建安全的输出路径
      final safePath = await fileSecurityValidator.createSafeOutputPath(
        '$_defaultFileName_${DateTime.now().millisecondsSinceEpoch}.json',
        'exports',
      );

      // 4. 验证文件路径
      final validationResult = await fileSecurityValidator.validateFile(
        safePath,
        checkWritePermission: true,
        checkType: true,
      );

      if (!validationResult.isValid) {
        Logger.debug('导出失败：${validationResult.errorMessage}');
        return false;
      }

      // 5. 写入文件
      final file = File(validationResult.sanitizedPath ?? safePath);
      await file.writeAsString(jsonString);

      // 6. 更新会话大小
      fileSecurityValidator.updateSessionSize(contentSize);

      Logger.debug('笔记导出成功: ${file.path}');
      return true;
    } catch (e) {
      Logger.debug('导出笔记时发生错误: $e');
      return false;
    }
  }

  /// 使用文件选择器导出（提供用户选择位置）
  static Future<bool> exportToFileWithPicker(List<Note> notes) async {
    try {
      final jsonString = await exportToJSON(notes);

      final contentSize = jsonString.length;
      if (contentSize > FileSecurityValidator.maxSingleFileSize) {
        Logger.debug('导出失败：内容过大');
        return false;
      }

      final String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Notes As JSON',
        fileName:
            '$_defaultFileName_${DateTime.now().millisecondsSinceEpoch}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (outputFile == null) {
        Logger.debug('用户取消了文件选择');
        return false;
      }

      // 验证用户选择的路径
      final validationResult = await fileSecurityValidator.validateFile(
        outputFile,
        checkWritePermission: true,
        checkType: true,
      );

      if (!validationResult.isValid) {
        Logger.debug('导出失败：${validationResult.errorMessage}');

        // 如果用户选择的路径不安全，使用安全路径
        final safePath = await fileSecurityValidator.createSafeOutputPath(
          '$_defaultFileName_${DateTime.now().millisecondsSinceEpoch}.json',
          'exports',
        );

        final file = File(safePath);
        await file.writeAsString(jsonString);
        fileSecurityValidator.updateSessionSize(contentSize);

        Logger.debug('使用安全路径导出: $safePath');
        return true;
      }

      final file = File(outputFile);
      await file.writeAsString(jsonString);
      fileSecurityValidator.updateSessionSize(contentSize);

      Logger.debug('笔记导出成功: ${file.path}');
      return true;
    } catch (e) {
      Logger.debug('使用文件选择器导出时发生错误: $e');
      return false;
    }
  }

  /// 安全导入笔记从文件
  ///
  /// 安全特性：
  /// - 路径验证：防止路径遍历攻击
  /// - 文件类型检查：只允许.json文件
  /// - 大小限制：检查文件大小是否在允许范围内
  /// - 内容验证：验证JSON格式
  /// - 沙箱隔离：使用安全的工作目录
  static Future<List<Note>> importFromFile() async {
    try {
      // 1. 使用文件选择器选择文件
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        Logger.debug('用户取消了文件选择');
        return [];
      }

      final selectedFile = result.files.single;
      if (selectedFile.path == null) {
        Logger.debug('文件路径无效');
        return [];
      }

      // 2. 验证文件路径
      final pathValidation = await fileSecurityValidator.validatePath(
        selectedFile.path!,
        requireExistence: true,
      );

      if (!pathValidation.isValid) {
        Logger.debug('导入失败：${pathValidation.errorMessage}');
        return [];
      }

      final validatedPath = pathValidation.sanitizedPath ?? selectedFile.path!;

      // 3. 验证文件类型
      final typeValidation =
          fileSecurityValidator.validateFileType(validatedPath);
      if (!typeValidation.isValid) {
        Logger.debug('导入失败：${typeValidation.errorMessage}');
        return [];
      }

      // 4. 验证文件大小
      final file = File(validatedPath);
      final fileSize = await file.length();

      if (fileSize > FileSecurityValidator.maxSingleFileSize) {
        Logger.debug('导入失败：文件过大 (${fileSize} bytes)');
        return [];
      }

      // 5. 检查会话总大小
      if (fileSecurityValidator.getCurrentSessionSize() + fileSize >
          FileSecurityValidator.maxTotalSize) {
        Logger.debug('导入失败：会话总大小超限');
        return [];
      }

      // 6. 读取并解析文件内容
      final jsonString = await file.readAsString();

      // 验证JSON格式
      try {
        final List<dynamic> json = jsonDecode(jsonString);

        final notes = <Note>[];

        for (final noteJson in json) {
          try {
            // 验证必需字段
            if (!_isValidNoteData(noteJson)) {
              Logger.debug('跳过无效的笔记数据: $noteJson');
              continue;
            }

            final note = Note(
              id: noteJson['id'],
              title: noteJson['title'] ?? 'Untitled',
              content: noteJson['content'] ?? '',
              createdAt: _parseDateTime(noteJson['createdAt']),
              updatedAt: _parseDateTime(noteJson['updatedAt']),
              tags: List<String>.from(noteJson['tags'] ?? []),
            );

            notes.add(note);
          } catch (e) {
            Logger.debug('解析笔记数据时出错: $e');
            continue;
          }
        }

        // 7. 更新会话大小
        fileSecurityValidator.updateSessionSize(fileSize);

        Logger.debug('成功导入 ${notes.length} 条笔记');
        return notes;
      } on FormatException catch (e) {
        Logger.debug('导入失败：无效的JSON格式 - $e');
        return [];
      }
    } catch (e) {
      Logger.debug('导入文件时发生错误: $e');
      return [];
    }
  }

  /// 验证笔记数据是否有效
  static bool _isValidNoteData(dynamic data) {
    if (data is! Map<String, dynamic>) return false;

    // 检查必需字段
    if (!data.containsKey('id') || data['id'] == null) return false;

    // 验证日期格式
    try {
      if (data['createdAt'] != null) {
        DateTime.parse(data['createdAt']);
      }
      if (data['updatedAt'] != null) {
        DateTime.parse(data['updatedAt']);
      }
    } catch (e) {
      return false;
    }

    return true;
  }

  /// 安全解析日期时间
  static DateTime _parseDateTime(dynamic dateTime) {
    if (dateTime == null) return DateTime.now();

    try {
      return DateTime.parse(dateTime);
    } catch (e) {
      Logger.debug('日期解析失败，使用当前时间: $e');
      return DateTime.now();
    }
  }

  /// 获取导出的统计信息
  static Map<String, dynamic> getExportStats() {
    return fileSecurityValidator.getSecurityStatus();
  }

  /// 重置会话大小
  static void resetSessionSize() {
    fileSecurityValidator.resetSessionSize();
  }

  /// 获取安全审计日志
  static List<SecurityAuditLog> getAuditLogs() {
    return fileSecurityValidator.getAuditLogs();
  }

  /// 导出安全审计日志
  static Future<String> exportAuditLogs() async {
    return await fileSecurityValidator.exportAuditLogs();
  }
}
