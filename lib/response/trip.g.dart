// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Trip _$TripFromJson(Map<String, dynamic> json) => Trip()
  ..tripId = json['id'] as String
  ..userId = json['user_id'] as String
  ..muatLat = (json['muat_lat'] as num).toDouble()
  ..muatLong = (json['muat_long'] as num).toDouble()
  ..bongkarLat = (json['bongkar_lat'] as num).toDouble()
  ..bongkarLong = (json['bongkar_long'] as num).toDouble()
  ..status = json['status'] as String
  ..createdAt = DateTime.parse(json['created_at'] as String)
  ..updatedAt = DateTime.parse(json['updated_at'] as String);

Map<String, dynamic> _$TripToJson(Trip instance) => <String, dynamic>{
      'id': instance.tripId,
      'user_id': instance.userId,
      'muat_lat': instance.muatLat,
      'muat_long': instance.muatLong,
      'bongkar_lat': instance.bongkarLat,
      'bongkar_long': instance.bongkarLong,
      'status': instance.status,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
