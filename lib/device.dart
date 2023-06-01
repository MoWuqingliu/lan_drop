import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class Device {
  Device(this.type, this.name, this.deviceId, this.address,
      [this.active = true]);

  final DeviceType type;
  final String name;
  final String deviceId;

  final InternetAddress address;
  final bool active;
}

enum DeviceType { android, pc }

class DeviceOrm {
  late Database database;
  static const tableName = "devices";

  void init() async {
    database =
        await openDatabase(join(await getDatabasesPath(), "device_cache.db"),
            onCreate: (db, version) {
      return db.execute(
          "CREATE TABLE  $tableName (deviceId TEXT PRIMARY KEY, name TEXT, type INT)");
    });
  }

  Future<List<Device>> queryAll() async {
    final List<Map<String, dynamic>> list = await database.query(tableName);
    return list
        .map((e) => Device(
            e['type'] == DeviceType.pc.index
                ? DeviceType.pc
                : DeviceType.android,
            e['name'],
            e['deviceId'],
            InternetAddress.anyIPv4,
            false))
        .toList();
  }

  Future<int> updateName(String name, String deviceId) async {
    return database.update(tableName, {'name': name},
        where: "deviceId = ?", whereArgs: [deviceId]);
  }

  Future<void> saveAll(List<Device> devices) async {
    await database.execute("delete from $tableName");
    for (var element in devices) {
      database.insert(tableName, {
        'name': element.name,
        'type': element.type.index,
        'deviceId': element.deviceId
      });
    }
  }
}
