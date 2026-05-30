// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'world_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocationAdapter extends TypeAdapter<Location> {
  @override
  final int typeId = 11;

  @override
  Location read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Location(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      relatedCharacters: (fields[3] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, Location obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.relatedCharacters);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class OrganizationAdapter extends TypeAdapter<Organization> {
  @override
  final int typeId = 12;

  @override
  Organization read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Organization(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      leader: fields[3] as String?,
      members: (fields[4] as List?)?.cast<String>(),
      philosophy: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Organization obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.leader)
      ..writeByte(4)
      ..write(obj.members)
      ..writeByte(5)
      ..write(obj.philosophy);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrganizationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WorldModelAdapter extends TypeAdapter<WorldModel> {
  @override
  final int typeId = 13;

  @override
  WorldModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorldModel(
      id: fields[0] as String,
      name: fields[1] as String,
      worldType: fields[2] as String,
      era: fields[3] as String?,
      magicSystem: fields[4] as String?,
      technology: fields[5] as String?,
      rules: (fields[6] as List?)?.cast<String>(),
      locations: (fields[7] as List?)?.cast<Location>(),
      organizations: (fields[8] as List?)?.cast<Organization>(),
      geography: fields[9] as String?,
      history: fields[10] as String?,
      tags: (fields[11] as List?)?.cast<String>(),
      createdAt: fields[12] as DateTime?,
      updatedAt: fields[13] as DateTime?,
      notes: fields[14] as String?,
      isActive: fields[15] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, WorldModel obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.worldType)
      ..writeByte(3)
      ..write(obj.era)
      ..writeByte(4)
      ..write(obj.magicSystem)
      ..writeByte(5)
      ..write(obj.technology)
      ..writeByte(6)
      ..write(obj.rules)
      ..writeByte(7)
      ..write(obj.locations)
      ..writeByte(8)
      ..write(obj.organizations)
      ..writeByte(9)
      ..write(obj.geography)
      ..writeByte(10)
      ..write(obj.history)
      ..writeByte(11)
      ..write(obj.tags)
      ..writeByte(12)
      ..write(obj.createdAt)
      ..writeByte(13)
      ..write(obj.updatedAt)
      ..writeByte(14)
      ..write(obj.notes)
      ..writeByte(15)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorldModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
