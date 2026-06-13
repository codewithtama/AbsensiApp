// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'site_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SiteModelAdapter extends TypeAdapter<SiteModel> {
  @override
  final typeId = 1;

  @override
  SiteModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SiteModel(
      id: fields[0] as String,
      name: fields[1] as String,
      latitude: (fields[2] as num).toDouble(),
      longitude: (fields[3] as num).toDouble(),
      radiusMeters: fields[4] == null
          ? GeofenceConfig.defaultRadiusMeters
          : (fields[4] as num).toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, SiteModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.latitude)
      ..writeByte(3)
      ..write(obj.longitude)
      ..writeByte(4)
      ..write(obj.radiusMeters);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SiteModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
