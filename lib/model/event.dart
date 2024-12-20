import 'dart:convert';

EventList EventFromJson(String str) {
  final jsonData = json.decode(str);
  return EventList.fromMap(jsonData);
}

class EventList {
  late int id;
  late String name;
  late String begin;
  late String end;
  late int eventColor;
  late int uid;

  EventList({
    required this.id,
    required this.name,
    required this.begin,
    required this.end,
    required this.eventColor,
    required this.uid,
  });

  factory EventList.fromMap(Map<String, dynamic> json) => EventList(
    id: json["id"],
    name: json["name"],
    begin: json["begin"],
    end: json["end"],
    eventColor: json["eventColor"],
    uid: json["uid"],
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "name": name,
    "begin": begin,
    "end": end,
    "eventColor": eventColor,
    "uid": uid,
  };
}
