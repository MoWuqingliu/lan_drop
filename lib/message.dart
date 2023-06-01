import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class Message {
  Message(this.isSend, this.type, this.content, this.dateTime);

  bool isSend;
  MessageType type;
  String content;
  DateTime dateTime;

}

enum MessageType { blob, text, image }

class MessageOrm {
  final String deviceId;
  late Database database;
  static const tableName = "messages";
  late int count;

  MessageOrm(this.deviceId);

  void init() async {
    database =
        await openDatabase(join(await getDatabasesPath(), "$deviceId.db"),
            onCreate: (db, version) {
      return db.execute(
          "CREATE TABLE  $tableName (id INTEGER PRIMARY KEY, isSend INT, messageType INT, content TEXT, dateTime INT)");
    });
    var rt =
        await database.rawQuery("select count(*) as count from $tableName");
    count = rt[0]['count'] as int;
  }

  void delete() async {
    database.close();
    deleteDatabase(join(await getDatabasesPath(), "$deviceId.db"));
  }

  void clear() {
    database.execute("delete from $tableName");
  }

  Future<List<Message>> query(int start, int size) async {
    List<Map<String, dynamic>> list = await database.query(tableName,
        offset: count - start - size, limit: size);
    return list
        .map((e) => Message(
            e['isSend'] == 1,
            MessageType.values
                .firstWhere((element) => e['messageType'] == element.index),
            e['content'],
            DateTime.fromMicrosecondsSinceEpoch(e['dataTime'])))
        .toList();
  }

  Future<int> add(Message message) async{
    return database.insert(tableName, {
      'isSend':message.isSend ? 1 : 0,
      'messageType':message.type.index,
      'content': message.content,
      'dateTime':message.dateTime.millisecond
    });
  }
}
