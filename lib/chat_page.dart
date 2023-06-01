

import 'package:chat_bubbles/chat_bubbles.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'device.dart';
import 'message.dart';
class ChatPage extends StatefulWidget {
  const ChatPage(this._device, {super.key});

  final Device _device;

  @override
  State<StatefulWidget> createState() {
    return ChatState();
  }
}

class ChatState extends State<ChatPage> {

  final _imagePicker = ImagePickerPlatform.instance;
  final messages = [
    Message(false, MessageType.text, "m4", DateTime.now()),
    Message(
        false,
        MessageType.text,
        "m31111111111111111111111111111111111111111111111111",
        DateTime.now().subtract(const Duration(days: 2))),
    Message(
        true,
        MessageType.text,
        "m31111111111111111111111111111111111111111111111111",
        DateTime.now().subtract(const Duration(days: 2))),
    Message(
        true,
        MessageType.image,
        "https://docimg8.docs.qq.com/image/AgAALIrlpVYFcr_Kp9hLHL0W-oo1VlaB.jpeg",
        DateTime(2008)),
    Message(true, MessageType.text, "https://cn.bing.com",
        DateTime.now().subtract(const Duration(days: 2))),
    Message(false, MessageType.text, "m1", DateTime.now()),
  ];

  _clean() async {

    debugPrint(
        "Chat with Device ${widget._device.name}:${widget._device.address} cleaned");
  }
  void _sendMessage(String p,[MessageType type = MessageType.text]) {
  }



  Widget _renderBlob(Message message) {
    return BubbleNormal(
      text: "Blob",
      color: Colors.cyan,
    );
  }

  Widget _renderMessage(BuildContext context, int index) {
    var message = messages[index];
    switch (message.type) {
      case MessageType.image:
        return BubbleNormalImage(
          id: 'id001',
          image: Image.network(message.content),
          isSender: message.isSend,
        );
      case MessageType.text:
        return InkWell(
          onDoubleTap: () {
            Clipboard.setData(ClipboardData(text: message.content));
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Copied"),
              duration: Duration(seconds: 1),
            ));
          },
          child: BubbleNormal(
            text: message.content,
            color: Colors.cyan,
            isSender: message.isSend,
          ),
        );
      case MessageType.blob:
        return _renderBlob(message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
              tooltip: "return to last page",
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context);
              }),
          title: Text(widget._device.name),
          centerTitle: true,
          actions: [
            IconButton(
                onPressed: _clean,
                icon: const Icon(Icons.delete_forever_rounded))
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemBuilder: (ctx, index) {
                  return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: _renderMessage(context, index));
                },
                itemCount: messages.length,
                reverse: true,
              ),
            ),
            MessageBar(
              onSend: (text){
                _alertIfDeviceIsNotOnline(context);
                if (widget._device.active){
                  _sendMessage(text);
                }
              },
              actions: [
                InkWell(
                  child: const Icon(
                    Icons.file_open,
                    color: Colors.green,
                    size: 24,
                  ),
                  onTap: () async{
                    _alertIfDeviceIsNotOnline(context);
                    if (!widget._device.active){
                      return;
                    }
                    var result = await FilePicker.platform.pickFiles(allowMultiple: true);
                    for(var file in result!.paths){
                      if(file != null){
                        debugPrint("file_picker: $file");
                        _sendMessage(file,MessageType.blob);
                      }
                    }
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8, right: 8),
                  child: InkWell(
                    child: const Icon(
                      Icons.image,
                      color: Colors.green,
                      size: 24,
                    ),
                    onTap: () async {
                      _alertIfDeviceIsNotOnline(context);
                      if (!widget._device.active){
                        return;
                      }
                      var images = await _imagePicker.getMultiImage();
                      for (var image in images!) {
                        debugPrint("path: ${image.path}, name: ${image.name}");
                        _sendMessage(image.path,MessageType.image);
                      }
                    },
                  ),
                ),
              ],
            )
          ],
        ));
  }

  bool _alertIfDeviceIsNotOnline(BuildContext context) {
    if (!widget._device.active){
      showDialog(context: context, builder: (context){
        return const AlertDialog(
          title: Text("Device is not online"),
          content: Text("You can only browse the history. If you want to send message, return back to the homepage and refresh it"),
        );
      });
    }
    return !widget._device.active;
  }


}
