import 'package:json_annotation/json_annotation.dart';

part 'user_response.g.dart';

@JsonSerializable()
class UserResponse {
  @JsonKey(name: "id")
  late int id;

  @JsonKey(name: "nik")
  late String nik;

  @JsonKey(name: "name")
  late String name;

  @JsonKey(name: "username")
  late String username;

  @JsonKey(name: "email")
  late String email;

  @JsonKey(name: "password")
  late String password;

  @JsonKey(name: "phone")
  late String phone;

  @JsonKey(name: "img_type")
  late String img_type;

  @JsonKey(name: "karyawan_divisi")
  late String karyawan_divisi;

  @JsonKey(name: "karyawan_jabatan")
  late String karyawan_jabatan;

  @JsonKey(name: "karyawan_mandiri")
  late String karyawan_mandiri;

  UserResponse();

  factory UserResponse.fromJson(Map<String, dynamic> json) =>
      _$UserResponseFromJson(json);
  Map<String, dynamic> toJson() => _$UserResponseToJson(this);
}
