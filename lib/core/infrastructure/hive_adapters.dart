import 'package:hive_ce/hive.dart';
import 'package:museflow/core/domain/app_settings.dart';
import 'package:museflow/core/domain/fragment.dart';
import 'package:museflow/features/knowledge/domain/character_card.dart';
import 'package:museflow/features/knowledge/domain/skill_document.dart';
import 'package:museflow/features/knowledge/domain/world_setting.dart';
import 'package:museflow/features/manuscript/domain/chapter.dart';
import 'package:museflow/features/manuscript/domain/chapter_summary.dart';
import 'package:museflow/features/manuscript/domain/manuscript.dart';
import 'package:museflow/features/stats/domain/token_audit_record.dart';
import 'package:museflow/features/story_structure/domain/foreshadowing_entry.dart';
import 'package:museflow/features/story_structure/domain/guardian_annotation.dart';
import 'package:museflow/features/story_structure/domain/plot_node.dart';

/// Type ID registry for Hive adapters.
/// Centralizes all type IDs to prevent conflicts.
abstract class HiveTypeIds {
  static const int fragment = 0;
  static const int appSettings = 1;
  static const int manuscript = 2;
  static const int characterCard = 3;
  static const int worldSetting = 4;
  static const int skillDocument = 5;
  static const int foreshadowingEntry = 6;
  static const int plotNode = 7;
  static const int guardianAnnotation = 8;
  static const int chapter = 9;
  static const int tokenAuditRecord = 10;
  static const int chapterSummary = 11;
}

/// Manual Hive TypeAdapter for [ChapterSummary].
class ChapterSummaryAdapter extends TypeAdapter<ChapterSummary> {
  @override
  final int typeId = HiveTypeIds.chapterSummary;

  @override
  ChapterSummary read(BinaryReader reader) {
    final json = reader.readMap() as Map<String, dynamic>;
    return ChapterSummary.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, ChapterSummary obj) {
    writer.writeMap(obj.toJson());
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChapterSummaryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

/// Manual Hive TypeAdapter for [Fragment].
///
/// Delegates serialization to freezed-generated fromJson/toJson.
class FragmentAdapter extends TypeAdapter<Fragment> {
  @override
  final int typeId = HiveTypeIds.fragment;

  @override
  Fragment read(BinaryReader reader) {
    final json = reader.readMap() as Map<String, dynamic>;
    return Fragment.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, Fragment obj) {
    writer.writeMap(obj.toJson());
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FragmentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

/// Manual Hive TypeAdapter for [AppSettings].
///
/// Delegates serialization to freezed-generated fromJson/toJson.
class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = HiveTypeIds.appSettings;

  @override
  AppSettings read(BinaryReader reader) {
    final json = reader.readMap() as Map<String, dynamic>;
    return AppSettings.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer.writeMap(obj.toJson());
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

/// Manual Hive TypeAdapter for [CharacterCard].
///
/// Delegates serialization to fromJson/toJson.
class CharacterCardAdapter extends TypeAdapter<CharacterCard> {
  @override
  final int typeId = HiveTypeIds.characterCard;

  @override
  CharacterCard read(BinaryReader reader) {
    final json = reader.readMap() as Map<String, dynamic>;
    return CharacterCard.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, CharacterCard obj) {
    writer.writeMap(obj.toJson());
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CharacterCardAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

/// Manual Hive TypeAdapter for [WorldSetting].
///
/// Delegates serialization to fromJson/toJson.
class WorldSettingAdapter extends TypeAdapter<WorldSetting> {
  @override
  final int typeId = HiveTypeIds.worldSetting;

  @override
  WorldSetting read(BinaryReader reader) {
    final json = reader.readMap() as Map<String, dynamic>;
    return WorldSetting.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, WorldSetting obj) {
    writer.writeMap(obj.toJson());
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorldSettingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SkillDocumentAdapter extends TypeAdapter<SkillDocument> {
  @override
  final int typeId = HiveTypeIds.skillDocument;

  @override
  SkillDocument read(BinaryReader reader) {
    final json = reader.readMap() as Map<String, dynamic>;
    return SkillDocument.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, SkillDocument obj) {
    writer.writeMap(obj.toJson());
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SkillDocumentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

/// Manual Hive TypeAdapter for [ForeshadowingEntry].
///
/// Delegates serialization to fromJson/toJson.
class ForeshadowingEntryAdapter extends TypeAdapter<ForeshadowingEntry> {
  @override
  final int typeId = HiveTypeIds.foreshadowingEntry;

  @override
  ForeshadowingEntry read(BinaryReader reader) {
    final json = reader.readMap() as Map<String, dynamic>;
    return ForeshadowingEntry.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, ForeshadowingEntry obj) {
    writer.writeMap(obj.toJson());
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ForeshadowingEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

/// Manual Hive TypeAdapter for [PlotNode].
///
/// Delegates serialization to fromJson/toJson.
class PlotNodeAdapter extends TypeAdapter<PlotNode> {
  @override
  final int typeId = HiveTypeIds.plotNode;

  @override
  PlotNode read(BinaryReader reader) {
    final json = reader.readMap() as Map<String, dynamic>;
    return PlotNode.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, PlotNode obj) {
    writer.writeMap(obj.toJson());
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlotNodeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

/// Manual Hive TypeAdapter for [GuardianAnnotation].
///
/// Delegates serialization to fromJson/toJson.
class GuardianAnnotationAdapter extends TypeAdapter<GuardianAnnotation> {
  @override
  final int typeId = HiveTypeIds.guardianAnnotation;

  @override
  GuardianAnnotation read(BinaryReader reader) {
    final json = reader.readMap() as Map<String, dynamic>;
    return GuardianAnnotation.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, GuardianAnnotation obj) {
    writer.writeMap(obj.toJson());
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GuardianAnnotationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

/// Manual Hive TypeAdapter for [Manuscript].
///
/// Delegates serialization to fromJson/toJson.
class ManuscriptAdapter extends TypeAdapter<Manuscript> {
  @override
  final int typeId = HiveTypeIds.manuscript;

  @override
  Manuscript read(BinaryReader reader) {
    final json = reader.readMap() as Map<String, dynamic>;
    return Manuscript.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, Manuscript obj) {
    writer.writeMap(obj.toJson());
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ManuscriptAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

/// Manual Hive TypeAdapter for [Chapter].
///
/// Delegates serialization to fromJson/toJson.
class ChapterAdapter extends TypeAdapter<Chapter> {
  @override
  final int typeId = HiveTypeIds.chapter;

  @override
  Chapter read(BinaryReader reader) {
    final json = reader.readMap() as Map<String, dynamic>;
    return Chapter.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, Chapter obj) {
    writer.writeMap(obj.toJson());
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChapterAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

/// Manual Hive TypeAdapter for [TokenAuditRecord].
///
/// Delegates serialization to fromJson/toJson.
class TokenAuditRecordAdapter extends TypeAdapter<TokenAuditRecord> {
  @override
  final int typeId = HiveTypeIds.tokenAuditRecord;

  @override
  TokenAuditRecord read(BinaryReader reader) {
    final json = reader.readMap() as Map<String, dynamic>;
    return TokenAuditRecord.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, TokenAuditRecord obj) {
    writer.writeMap(obj.toJson());
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TokenAuditRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
