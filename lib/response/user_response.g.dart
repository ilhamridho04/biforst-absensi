// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserResponse _$UserResponseFromJson(Map<String, dynamic> json) => UserResponse()
  ..id = (json['id'] as num).toInt()
  ..nik = json['nik'] as String
  ..name = json['name'] as String
  ..username = json['username'] as String
  ..email = json['email'] as String
  ..password = json['password'] as String
  ..phone = json['phone'] as String
  ..img_type = json['img_type'] as String
  ..karyawan_divisi = json['karyawan_divisi'] as String
  ..karyawan_jabatan = json['karyawan_jabatan'] as String
  ..karyawan_mandiri = json['karyawan_mandiri'] as String;

Map<String, dynamic> _$UserResponseToJson(UserResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nik': instance.nik,
      'name': instance.name,
      'username': instance.username,
      'email': instance.email,
      'password': instance.password,
      'phone': instance.phone,
      'img_type': instance.img_type,
      'karyawan_divisi': instance.karyawan_divisi,
      'karyawan_jabatan': instance.karyawan_jabatan,
      'karyawan_mandiri': instance.karyawan_mandiri,
    };
