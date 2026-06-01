import 'package:hive_ce/hive.dart';
import 'package:museflow/core/domain/app_settings.dart';
import 'package:museflow/core/domain/fragment.dart';

/// Type ID registry for Hive adapters.
/// Centralizes all type IDs to prevent conflicts.
abstract class HiveTypeIds {
  static const int fragment = 0;
  static const int appSettings = 1;
  static const int manuscript = 2;
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
      other is FragmentAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
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
