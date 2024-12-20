import 'package:json_annotation/json_annotation.dart';

part 'riwayat_absensi_response.g.dart';

@JsonSerializable()
class RiwayatAbsensiResponse {
  @JsonKey(name: "id")
  late int id;

  @JsonKey(name: "absen_user_id")
  late int absen_user_id;

  @JsonKey(name: "absen_tanggal")
  late String absen_tanggal;

  @JsonKey(name: "absen_jam_masuk")
  late String absen_jam_masuk;

  @JsonKey(name: "absen_jam_pulang")
  late String absen_jam_pulang;

  @JsonKey(name: "absen_jam_lewat")
  late String absen_jam_lewat;

  @JsonKey(name: "absen_jam_terlambat")
  late String absen_jam_terlambat;

  @JsonKey(name: "absen_pulang_cepat")
  late String absen_pulang_cepat;

  @JsonKey(name: "absen_area_in")
  late String absen_area_in;

  @JsonKey(name: "absen_area_out")
  late String absen_area_out;

  @JsonKey(name: "longt_out")
  late String longt_out;

  @JsonKey(name: "lat_out")
  late String lat_out;

  @JsonKey(name: "absen_foto")
  late String absen_foto;

  @JsonKey(name: "created_at")
  late String created_at;

  @JsonKey(name: "updated_at")
  late String updated_at;

  @JsonKey(name: "area")
  late String area;

  RiwayatAbsensiResponse();

  factory RiwayatAbsensiResponse.fromJson(Map<String, dynamic> json) =>
      _$RiwayatAbsensiResponseFromJson(json);
  Map<String, dynamic> toJson() => _$RiwayatAbsensiResponseToJson(this);
}
