import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../model/attendance.dart';
import '../model/event.dart';
import '../model/settings.dart';
import '../model/user.dart';

class DbHelper {
  static DbHelper? _dbHelper;
  static Database? _database;

  // Db name file
  String dbName = 'attendance.db';

  // table name
  String tableSettings = 'settings';
  String tableAttendance = 'attendances';
  String tableUser = 'user';
  String tableEvent = 'event';

  DbHelper._createObject();

  factory DbHelper() {
    if (_dbHelper == null) {
      _dbHelper = DbHelper._createObject();
    }
    return _dbHelper!;
  }

  Future<Database> initDb() async {
    // Init name and directory of DB
    Directory directory = await getApplicationDocumentsDirectory();
    String path = directory.path + dbName;

    // Create, read databases
    var todoDatabase = openDatabase(path, version: 1, onCreate: _createDb);
    return todoDatabase;
  }

  // Create the table
  void _createDb(Database db, int version) async {
    // Table for settings
    await db.execute('''
      CREATE TABLE $tableSettings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        url TEXT,
        key TEXT
        )
    ''');

    // Table for Attendance
    await db.execute('''
      CREATE TABLE $tableAttendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT,
        time TEXT,
        location TEXT,
        type TEXT
        )
    ''');

    // Table for Attendance
    await db.execute('''
      CREATE TABLE $tableUser (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uid INTEGER,
        nik TEXT,
        nama TEXT,
        email TEXT,
        role INTEGER,
        status INTEGER
        )
    ''');
    // Table for Event
    await db.execute('''
      CREATE TABLE $tableEvent (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        begin TEXT,
        end TEXT,
        eventColor INTEGER,
        uid INTEGER
        )
    ''');
  }

  Future<Database> get database async {
    if (_database == null) {
      _database = await initDb();
    }
    return _database!;
  }

  //--------------------------- Settings --------------------------------------
  // Check there is any data
  countSettings() async {
    final db = await database;
    int? count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $tableSettings'));
    return count;
  }

  // Insert new data
  newSettings(Settings newSettings) async {
    final db = await database;
    var result = await db.insert(tableSettings, newSettings.toMap());
    return result;
  }

  // Get the data by id
  getSettings(int id) async {
    final db = await database;
    var res = await db.query(tableSettings, where: "id = ?", whereArgs: [id]);
    return res.isNotEmpty ? Settings.fromMap(res.first) : null;
  }

  // Get the data by id
  deleteSettings(int id) async {
    final db = await database;
    var res = await db.delete(tableSettings, where: "id = ?", whereArgs: [id]);
    return res;
  }

  // Update the data
  updateSettings(Settings updateSettings) async {
    final db = await database;
    var result = await db.update(tableSettings, updateSettings.toMap(),
        where: "id = ?", whereArgs: [updateSettings.id]);
    return result;
  }

  //--------------------------- Attendance -------------------------------------

  // Insert new data attendance
  newAttendances(Attendance newAttendance) async {
    final db = await database;
    var result = await db.insert(tableAttendance, newAttendance.toMap());
    return result;
  }

  Future<List<Attendance>> getAttendances() async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.rawQuery(
        "SELECT * FROM $tableAttendance ORDER BY date(date) DESC, time(time) DESC");
    List<Attendance> employees = [];
    if (maps.length > 0) {
      for (int i = 0; i < maps.length; i++) {
        employees.add(Attendance.fromMap(maps[i]));
      }
    }
    return employees;
  }

  // Get All attendance
  getAbsenNew(String date) async {
    final db = await database;
    var res =
    await db.query(tableAttendance, where: "date = ?", whereArgs: [date]);
    return res.isNotEmpty ? Attendance.fromMap(res.first) : null;
  }

  //--------------------------- User --------------------------------------
  // Check there is any data
  countUser() async {
    final db = await database;
    int? count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $tableUser'));
    return count;
  }

  // Insert new data
  newUser(User newUser) async {
    final db = await database;
    var result = await db.insert(tableUser, newUser.toMap());
    return result;
  }

  // Get the data by id
  getUser(int id) async {
    final db = await database;
    var res = await db.query(tableUser, where: "id = ?", whereArgs: [id]);
    return res.isNotEmpty ? User.fromMap(res.first) : null;
  }

  // Update the data
  updateUser(User updateUser) async {
    final db = await database;
    var result = await db.update(tableUser, updateUser.toMap(),
        where: "id = ?", whereArgs: [updateUser.id]);
    return result;
  }

  // Insert new data Event
  newEvent(EventList newEvent) async {
    final db = await database;
    var result = await db.insert(tableEvent, newEvent.toMap());
    return result;
  }

  // get data Event by User
  getEventById(int uid) async {
    final db = await database;
    var res = await db.query(tableEvent, where: "uid = ?", whereArgs: [uid]);
    return res;
  }

  Future<List<EventList>> getEventList() async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query("$tableEvent");
    List<EventList> eventList = [];
    if (maps.length > 0) {
      for (int i = 0; i < maps.length; i++) {
        eventList.add(EventList.fromMap(maps[i]));
      }
    }
    return eventList;
  }

  countEvent() async {
    final db = await database;
    int? count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $tableEvent'));
    return count;
  }

  // Update the data Event by User
  updateEvent(EventList updateEvent) async {
    final db = await database;
    var result = await db.update(tableEvent, updateEvent.toMap(),
        where: "id = ?", whereArgs: [updateEvent.id]);
    return result;
  }
}
