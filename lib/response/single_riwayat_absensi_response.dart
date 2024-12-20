import 'package:attendance/response/riwayat_absensi_response.dart';
import 'package:json_annotation/json_annotation.dart';

part 'single_riwayat_absensi_response.g.dart';

@JsonSerializable()
class SingleRiwayatAbsensiResponse {
  SingleRiwayatAbsensiResponse();

  @JsonKey(name: "data")
  late RiwayatAbsensiResponse riwayatAbsensi;

  factory SingleRiwayatAbsensiResponse.fromJson(Map<String, dynamic> json) =>
      _$SingleRiwayatAbsensiResponseFromJson(json);
  Map<String, dynamic> toJson() => _$SingleRiwayatAbsensiResponseToJson(this);
}
