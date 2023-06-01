import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:lan_drop/message.dart';
import 'package:udp/udp.dart';
import 'package:path/path.dart' as p;
import 'device.dart';

///  Binary format of message
///  msg | content_type | has_extra_binary | content | extra_binary
///  msg:
///   0 - greet
///   1 - response to greet
///   2 - send message
///   255 - error
///  content_type:
///   0 - plain text
///   1 - json
///  has_extra_binary:
///   0 - false
///   1 - true
///  content: text content encode with utf8
///  extra_binary: binary data
///

typedef NewDeviceListener = void Function(Device device);
typedef NewMessageListener = void Function(Message message);

const _port = 9411;

class Communication {
  late String _deviceName;
  late String _deviceId;

  final Map<InternetAddress, Socket> _connections = {};
  final List<NewDeviceListener> _deviceListeners = [];
  final List<NewMessageListener> _messageListeners = [];

  void greetAll() async {
    //todo
    var sender = await UDP.bind(Endpoint.any());
    Map<String, dynamic> messages = {
      "device":
          Platform.isAndroid ? DeviceType.android.index : DeviceType.pc.index,
      "name": _deviceName,
      "id": _deviceId,
    };
    var msg = List<int>.empty(growable: true);
    msg.add(0);
    msg.add(1);
    msg.add(0);
    var text = jsonEncode(messages).codeUnits;
    msg.addAll(text);
    // await sender.send(msg, Endpoint.broadcast(port: _port));
    debugPrint("greet all");
    sender.close();
  }

  void _responseToGreet(InternetAddress address) async {
    Map<String, dynamic> messages = {
      "device":
          Platform.isAndroid ? DeviceType.android.index : DeviceType.pc.index,
      "name": _deviceName,
      "id": _deviceId,
    };
    var msg = List<int>.empty(growable: true);
    msg.add(1);
    msg.add(1);
    msg.add(0);
    var text = jsonEncode(messages).codeUnits;
    var length = text.length;
    msg.add(length);
    msg.addAll(text);

    var sender = await Socket.connect(address, _port);
    _connections[address] = sender;
    sender.write(Uint8List.fromList(msg));
    sender.flush();
  }

  void sendMessage(Message message, Device device) async {
    debugPrint("send message with content ${message.content}");
    var sender = _connections[device.address]!;

    var msg = List<int>.empty(growable: true);
    msg.add(2);
    msg.add(0);
    if (message.type == MessageType.text) {
      msg.add(0);
      var text = message.content.codeUnits;
      var length = text.length;
      if (length < 256) {
        msg.add(0);
      }
      msg.add(length);
      msg.addAll(text);
    } else if (message.type == MessageType.blob ||
        message.type == MessageType.image) {
      msg.add(1);
      var f = File(message.content);
      var name = p.basename(message.content).codeUnits;
      var length = name.length;
      if (length < 256) {
        msg.add(0);
      }
      msg.add(length);
      msg.addAll(name);
      var content = f.readAsBytesSync();
      var size = content.length;
      var sizeOfSize = size.bitLength;
      if (sizeOfSize < 256) {
        msg.add(0);
      }
      msg.add(sizeOfSize);
      msg.add(size);
      msg.addAll(content);
    }
    sender.write(Uint8List.fromList(msg));
    sender.flush();
  }

  void startListen() async {
    if (Platform.isAndroid) {
      var deviceData = await DeviceInfoPlugin().androidInfo;
      _deviceName = deviceData.device;
      _deviceId = deviceData.id;
    } else if (Platform.isWindows) {
      var deviceData = await DeviceInfoPlugin().windowsInfo;
      _deviceName = deviceData.computerName;
      _deviceId = deviceData.deviceId;
    }

    var socket = await ServerSocket.bind(InternetAddress.anyIPv4, _port);
    socket.listen((socket) {
      socket.listen((data) {
        var type = data[0];
        if (type == 1) {
          var contentLength = (data[3] << 8) + data[4];
          var content =
              String.fromCharCodes(data.sublist(5, 5 + contentLength));
          var properties = jsonDecode(content);
          var device = Device(
              DeviceType.values.firstWhere(
                  (element) => element.index == properties['deviceType']),
              properties['deviceName'],
              properties['deviceId'],
              socket.remoteAddress,
              true);
          _responseToGreet(socket.remoteAddress);
          for (var fun in _deviceListeners) {
            fun(device);
          }
        } else if (type == 2) {

        } else {
          debugPrint("Message format is incorrect with message type $type");
        }
      });
    });

    RawDatagramSocket.bind(InternetAddress.anyIPv4, _port);
  }

  void addNewDeviceListener(NewDeviceListener listener) =>
      _deviceListeners.add(listener);

  void addNewMessageListener(NewMessageListener listener) =>
      _messageListeners.add(listener);
}
