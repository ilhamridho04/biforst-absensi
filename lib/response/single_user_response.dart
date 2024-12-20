import 'package:attendance/response/user_response.dart';
import 'package:json_annotation/json_annotation.dart';

part 'single_user_response.g.dart';

@JsonSerializable()
class SingleUserResponse {
  SingleUserResponse();

  @JsonKey(name: "data")
  late UserResponse userResponse;

  factory SingleUserResponse.fromJson(Map<String, dynamic> json) =>
      _$SingleUserResponseFromJson(json);
  Map<String, dynamic> toJson() => _$SingleUserResponseToJson(this);
}
