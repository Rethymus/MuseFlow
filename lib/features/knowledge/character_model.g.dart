// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CharacterModelAdapter extends TypeAdapter<CharacterModel> {
  @override
  final int typeId = 10;

  @override
  CharacterModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CharacterModel(
      id: fields[0] as String,
      name: fields[1] as String,
      age: fields[2] as int?,
      appearance: fields[3] as String?,
      personality: fields[4] as String?,
      background: fields[5] as String?,
      speakingStyle: fields[6] as String?,
      relationships: (fields[7] as List?)?.cast<String>(),
      tags: (fields[8] as List?)?.cast<String>(),
      createdAt: fields[9] as DateTime?,
      updatedAt: fields[10] as DateTime?,
      avatarPath: fields[11] as String?,
      notes: fields[12] as String?,
      isActive: fields[13] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, CharacterModel obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.age)
      ..writeByte(3)
      ..write(obj.appearance)
      ..writeByte(4)
      ..write(obj.personality)
      ..writeByte(5)
      ..write(obj.background)
      ..writeByte(6)
      ..write(obj.speakingStyle)
      ..writeByte(7)
      ..write(obj.relationships)
      ..writeByte(8)
      ..write(obj.tags)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.updatedAt)
      ..writeByte(11)
      ..write(obj.avatarPath)
      ..writeByte(12)
      ..write(obj.notes)
      ..writeByte(13)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CharacterModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
