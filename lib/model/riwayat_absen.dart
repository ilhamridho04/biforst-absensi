import 'dart:convert';

RiwayatAbsensi RiwayatAbsensiFromJson(String str) =>
    RiwayatAbsensi.fromJson(json.decode(str));

String RiwayatAbsensiModelToJson(RiwayatAbsensi data) =>
    json.encode(data.toJson());

class RiwayatAbsensi {
  RiwayatAbsensi({
    this.status,
    this.message,
    this.data,
  });

  String? status;
  String? message;
  List<RiwayatAbsensiList>? data;

  factory RiwayatAbsensi.fromJson(Map<String, dynamic> json) => RiwayatAbsensi(
    status: json["status"],
    message: json["message"],
    data: List<RiwayatAbsensiList>.from(
        json["data"].map((x) => RiwayatAbsensiList.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "data": List<dynamic>.from(data!.map((x) => x.toJson())),
  };
}

class RiwayatAbsensiList {
  RiwayatAbsensiList({
    this.absen_user_id,
    this.absen_tanggal,
    this.absen_jam_masuk,
    this.absen_jam_pulang,
    this.absen_jam_kerja,
    this.absen_jam_lewat,
    this.absen_jam_terlambat,
    this.absen_pulang_cepat,
    this.absen_area_in,
    this.absen_area_out,
    this.longt_out,
    this.lat_out,
    this.absen_foto,
    this.created_at,
    this.updated_at,
    this.area,
  });

  int? absen_user_id;
  String? absen_tanggal;
  String? absen_jam_masuk;
  String? absen_jam_pulang;
  String? absen_jam_kerja;
  String? absen_jam_lewat;
  String? absen_jam_terlambat;
  String? absen_pulang_cepat;
  int? absen_area_in;
  String? absen_area_out;
  String? longt_out;
  String? lat_out;
  String? absen_foto;
  String? created_at;
  String? updated_at;
  String? area;

  factory RiwayatAbsensiList.fromJson(Map<String, dynamic> json) =>
      RiwayatAbsensiList(
        absen_user_id: json['absen_user_id'],
        absen_tanggal: json['absen_tanggal'],
        absen_jam_masuk: json['absen_jam_masuk'],
        absen_jam_pulang: json['absen_jam_pulang'],
        absen_jam_kerja: json['absen_jam_kerja'],
        absen_jam_lewat: json['absen_jam_lewat'],
        absen_jam_terlambat: json['absen_jam_terlambat'],
        absen_pulang_cepat: json['absen_pulang_cepat'],
        absen_area_in: json['absen_area_in'],
        absen_area_out: json['absen_area_out'],
        longt_out: json['longt_out'],
        lat_out: json['lat_out'],
        absen_foto: json['absen_foto'],
        created_at: json['created_at'],
        updated_at: json['updated_at'],
        area: json['area'],
      );

  Map<String, dynamic> toJson() => {
    "absen_user_id": absen_user_id,
    "absen_tanggal": absen_tanggal,
    "absen_jam_masuk": absen_jam_masuk,
    "absen_jam_pulang": absen_jam_pulang,
    "absen_jam_kerja": absen_jam_kerja,
    "absen_jam_lewat": absen_jam_lewat,
    "absen_jam_terlambat": absen_jam_terlambat,
    "absen_pulang_cepat": absen_pulang_cepat,
    "absen_area_in": absen_area_in,
    "absen_area_out": absen_area_out,
    "longt_out": longt_out,
    "lat_out": lat_out,
    "absen_foto": absen_foto,
    "created_at": created_at,
    "updated_at": updated_at,
    "area": area,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is RiwayatAbsensiList &&
              runtimeType == other.runtimeType &&
              absen_user_id == other.absen_user_id;

  @override
  int get hashCode => absen_user_id.hashCode;
}
