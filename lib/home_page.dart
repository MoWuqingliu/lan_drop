import 'dart:io';

import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'chat_page.dart';
import 'device.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() {
    return HomePageState();
  }
}

class HomePageState extends State<HomePage> {

  int _count = 10;

  @override
  void initState() {
    super.initState();
  }

  void _clearConnections() {

  }

  void _refresh() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _count = (_count + 3) % 10;
    });
    // _controller.finishRefresh();
    // _controller.resetHeader();
  }

  final List<Device> _devices = [
    Device(DeviceType.android, "Phone", "ee", InternetAddress.anyIPv4),
    Device(DeviceType.pc, "PC", "ee", InternetAddress.anyIPv4, false),
    Device(DeviceType.android, "android", "ee", InternetAddress.anyIPv4),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("LAN Drop"),
          actions: [
            IconButton(
                onPressed: () async {
                  var rt = await showDialog<bool>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text("Caution!"),
                          content: const Text("Remove all histories?"),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text("Yes")),
                            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("No")),
                          ],
                        );
                      });
                  if (rt ?? false) {
                    _clearConnections();
                  }
                },
                icon: const Icon(Icons.delete_forever)),
            // IconButton(onPressed: () {}, icon: const Icon(Icons.refresh)),
          ],
        ),
        body: EasyRefresh(
            onRefresh: _refresh,
            child: ListView.builder(
              itemBuilder: (ctx, index) {
                var device = _devices[index % _devices.length];
                return Container(
                  decoration: BoxDecoration(
                      color: device.active
                          ? Colors.white
                          : Colors.grey.withOpacity(0.2)),
                  child: ListTile(
                    leading: Icon(device.getIcon()),
                    title: Text(device.name),
                    subtitle: Text(device.address.address),
                    trailing: const Icon(Icons.navigate_next),
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) {
                        return ChatPage(device);
                      }));
                    },
                  ),
                );
              },
              itemCount: _count,
            )));
  }
}

extension GetIcon on Device {
  IconData getIcon() {
    return type == DeviceType.android ? Icons.android : Icons.computer;
  }
}
