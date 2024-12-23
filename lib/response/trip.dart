import 'package:json_annotation/json_annotation.dart';

part 'trip.g.dart';

@JsonSerializable()
class Trip {
  @JsonKey(name: 'id')
  late String tripId;

  @JsonKey(name: 'user_id')
  late String userId;

  @JsonKey(name: 'muat_lat')
  late double muatLat;

  @JsonKey(name: 'muat_long')
  late double muatLong;

  @JsonKey(name: 'bongkar_lat')
  late double bongkarLat;

  @JsonKey(name: 'bongkar_long')
  late double bongkarLong;

  @JsonKey(name: 'status')
  late String status;

  @JsonKey(name: 'created_at')
  late DateTime createdAt;

  @JsonKey(name: 'updated_at')
  late DateTime updatedAt;

  Trip();

  factory Trip.fromJson(Map<String, dynamic> json) => _$TripFromJson(json);
  Map<String, dynamic> toJson() => _$TripToJson(this);
}