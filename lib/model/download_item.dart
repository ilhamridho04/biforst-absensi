import 'dart:convert';

DownloadItems downloadFromJson(String str) {
  final jsonData = json.decode(str);
  return DownloadItems.fromMap(jsonData);
}

String downloadToJson(DownloadItems data) {
  final dyn = data.toMap();
  return json.encode(dyn);
}

class DownloadItems {
  String name;
  String url;

  DownloadItems({required this.name, required this.url});

  factory DownloadItems.fromMap(Map<String, dynamic> json) => DownloadItems(
    name: json["name"],
    url: json["url"],
  );

  Map<String, dynamic> toMap() => {
    "name": name,
    "url": url,
  };
}
