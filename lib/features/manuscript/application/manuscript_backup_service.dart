import 'dart:convert';

import 'package:museflow/features/manuscript/domain/chapter.dart';
import 'package:museflow/features/manuscript/domain/manuscript.dart';
import 'package:museflow/features/manuscript/infrastructure/chapter_repository.dart';
import 'package:museflow/features/manuscript/infrastructure/manuscript_repository.dart';
import 'package:uuid/uuid.dart';

class ManuscriptBackupResult {
  const ManuscriptBackupResult({
    required this.manuscriptCount,
    required this.chapterCount,
  });

  final int manuscriptCount;
  final int chapterCount;
}

class ManuscriptBackupService {
  factory ManuscriptBackupService({
    required ManuscriptRepository manuscriptRepository,
    required ChapterRepository chapterRepository,
  }) {
    return ManuscriptBackupService._(manuscriptRepository, chapterRepository);
  }

  ManuscriptBackupService._(
    this._manuscriptRepository,
    this._chapterRepository,
  );

  static const schema = 'museflow.manuscripts.v1';

  final ManuscriptRepository _manuscriptRepository;
  final ChapterRepository _chapterRepository;
  final Uuid _uuid = const Uuid();

  String exportJson() {
    final manuscripts = _manuscriptRepository.getAll();
    final chapters = _chapterRepository.getAll();
    return const JsonEncoder.withIndent('  ').convert({
      'schema': schema,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'manuscripts': manuscripts.map((item) => item.toJson()).toList(),
      'chapters': chapters
          .where(
            (chapter) => manuscripts.any(
              (manuscript) => manuscript.id == chapter.manuscriptId,
            ),
          )
          .map((item) => item.toJson())
          .toList(),
    });
  }

  Future<ManuscriptBackupResult> importJson(String source) async {
    final parsed = jsonDecode(source);
    if (parsed is! Map) {
      throw const FormatException('备份文件必须是 JSON 对象');
    }
    final data = Map<String, dynamic>.from(parsed);
    if (data['schema'] != schema) {
      throw const FormatException('不支持的 MuseFlow 备份版本');
    }

    final manuscriptData = _mapList(data['manuscripts'], 'manuscripts');
    final chapterData = _mapList(data['chapters'], 'chapters');
    final manuscripts = manuscriptData.map(Manuscript.fromJson).toList();
    final chapters = chapterData.map(Chapter.fromJson).toList();
    final exportedIds = manuscripts.map((item) => item.id).toSet();
    final exportedChapterIds = chapters.map((item) => item.id).toSet();
    if (exportedIds.length != manuscripts.length || exportedIds.contains('')) {
      throw const FormatException('备份中包含重复或空白的文稿 ID');
    }
    if (exportedChapterIds.length != chapters.length ||
        exportedChapterIds.contains('')) {
      throw const FormatException('备份中包含重复或空白的章节 ID');
    }
    if (chapters.any((item) => !exportedIds.contains(item.manuscriptId))) {
      throw const FormatException('备份中存在无法归属到文稿的章节');
    }

    final manuscriptIdMap = <String, String>{};
    final insertedManuscriptIds = <String>[];
    final insertedChapterIds = <String>[];
    try {
      for (final manuscript in manuscripts) {
        final hasCollision =
            _manuscriptRepository.getById(manuscript.id) != null;
        final targetId = hasCollision ? _uuid.v4() : manuscript.id;
        manuscriptIdMap[manuscript.id] = targetId;
        final restored = manuscript.copyWith(
          id: targetId,
          title: hasCollision ? '${manuscript.title}（导入）' : manuscript.title,
          deletedAt: null,
        );
        await _manuscriptRepository.add(restored);
        insertedManuscriptIds.add(targetId);
      }

      for (final chapter in chapters) {
        final targetId = _chapterRepository.getById(chapter.id) == null
            ? chapter.id
            : _uuid.v4();
        final restored = chapter.copyWith(
          id: targetId,
          manuscriptId: manuscriptIdMap[chapter.manuscriptId]!,
        );
        await _chapterRepository.add(restored);
        insertedChapterIds.add(targetId);
      }
    } catch (error, stackTrace) {
      for (final id in insertedChapterIds.reversed) {
        await _chapterRepository.delete(id);
      }
      for (final id in insertedManuscriptIds.reversed) {
        await _manuscriptRepository.delete(id);
      }
      Error.throwWithStackTrace(error, stackTrace);
    }

    return ManuscriptBackupResult(
      manuscriptCount: insertedManuscriptIds.length,
      chapterCount: insertedChapterIds.length,
    );
  }

  List<Map<String, dynamic>> _mapList(Object? value, String field) {
    if (value is! List) {
      throw FormatException('备份缺少 $field 列表');
    }
    return value.map((item) {
      if (item is! Map) {
        throw FormatException('$field 包含无效记录');
      }
      return Map<String, dynamic>.from(item);
    }).toList();
  }
}
