// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'riwayat_absensi_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RiwayatAbsensiResponse _$RiwayatAbsensiResponseFromJson(
    Map<String, dynamic> json) =>
    RiwayatAbsensiResponse()
      ..id = json['id'] as int
      ..absen_user_id = json['absen_user_id'] as int
      ..absen_tanggal = json['absen_tanggal'] as String
      ..absen_jam_masuk = json['absen_jam_masuk'] as String
      ..absen_jam_pulang = json['absen_jam_pulang'] as String
      ..absen_jam_lewat = json['absen_jam_lewat'] as String
      ..absen_jam_terlambat = json['absen_jam_terlambat'] as String
      ..absen_pulang_cepat = json['absen_pulang_cepat'] as String
      ..absen_area_in = json['absen_area_in'] as String
      ..absen_area_out = json['absen_area_out'] as String
      ..longt_out = json['longt_out'] as String
      ..lat_out = json['lat_out'] as String
      ..absen_foto = json['absen_foto'] as String
      ..created_at = json['created_at'] as String
      ..updated_at = json['updated_at'] as String
      ..area = json['area'] as String;

Map<String, dynamic> _$RiwayatAbsensiResponseToJson(
    RiwayatAbsensiResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'absen_user_id': instance.absen_user_id,
      'absen_tanggal': instance.absen_tanggal,
      'absen_jam_masuk': instance.absen_jam_masuk,
      'absen_jam_pulang': instance.absen_jam_pulang,
      'absen_jam_lewat': instance.absen_jam_lewat,
      'absen_jam_terlambat': instance.absen_jam_terlambat,
      'absen_pulang_cepat': instance.absen_pulang_cepat,
      'absen_area_in': instance.absen_area_in,
      'absen_area_out': instance.absen_area_out,
      'longt_out': instance.longt_out,
      'lat_out': instance.lat_out,
      'absen_foto': instance.absen_foto,
      'created_at': instance.created_at,
      'updated_at': instance.updated_at,
      'area': instance.area,
    };
