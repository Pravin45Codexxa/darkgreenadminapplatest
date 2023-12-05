import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../Helper/Color.dart';
import '../Helper/Constant.dart';
import '../Helper/Session.dart';
import '../Helper/String.dart';
import '../Model/Model.dart';

StreamController<String>? chatstreamdata;

class Chat extends StatefulWidget {
  final String? id, status;
  const Chat({Key? key, this.id, this.status}) : super(key: key);

  @override
  _ChatState createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  TextEditingController msgController = TextEditingController();
  List<File> files = [];
  List<Model> chatList = [];
  late Map<String?, String> downloadlist;
  String _filePath = "";
  final ScrollController _scrollController = ScrollController();
  Future<List<Directory>?>? _externalStorageDirectories;

  @override
  void initState() {
    super.initState();
    downloadlist = <String?, String>{};
    setupChannel();
    CUR_TICK_ID = widget.id;
    FlutterDownloader.registerCallback(downloadCallback);
    getMsg();
  }

  static void downloadCallback(String id, int status, int progress) {
    final SendPort send =
        IsolateNameServer.lookupPortByName('downloader_send_port')!;
    send.send([id, status, progress]);
  }

  void setupChannel() {
    chatstreamdata = StreamController<String>(); //.broadcast();
    chatstreamdata!.stream.listen(
      (response) {
        setState(
          () {
            final res = json.decode(response);
            Model message;
            message = Model.fromChat(
              res["data"],
            );

            chatList.insert(0, message);
            files.clear();
          },
        );
      },
    );
  }

  @override
  void dispose() {
    CUR_TICK_ID = '';
    if (chatstreamdata != "") chatstreamdata!.sink.close();

    super.dispose();
  }

  void insertItem(String response) {
    if (chatstreamdata != "") chatstreamdata!.sink.add(response);
    _scrollController.animateTo(0.0,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getAppBar(
        getTranslated(context, CHATText)!,
        context,
      ),
      body: Column(
        children: <Widget>[
          buildListMessage(),
          msgRow(),
        ],
      ),
    );
  }

  Widget buildListMessage() {
    return Flexible(
      child: ListView.builder(
        padding: const EdgeInsets.all(10.0),
        itemBuilder: (context, index) => msgItem(index, chatList[index]),
        itemCount: chatList.length,
        reverse: true,
        controller: _scrollController,
      ),
    );
  }

  Widget msgItem(int index, Model message) {
    if (message.uid == CUR_USERID) {
      //Own message
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Flexible(
            flex: 1,
            child: Container(),
          ),
          Flexible(
            flex: 2,
            child: msgContent(index, message),
          ),
        ],
      );
    } else {
      //Other's message
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Flexible(
            flex: 2,
            child: msgContent(index, message),
          ),
          Flexible(
            flex: 1,
            child: Container(),
          ),
        ],
      );
    }
  }

  Widget msgContent(int index, Model message) {
    //String filetype = message.attachment_mime_type.trim();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: message.uid == CUR_USERID
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: <Widget>[
        message.uid == CUR_USERID || (message.msg == "" || message.msg!.isEmpty)
            ? Container()
            : Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(left: 5.0),
                      child: Text(capitalize(message.name!),
                          style: const TextStyle(color: primary, fontSize: 12)),
                    )
                  ],
                ),
              ),
        ListView.builder(
            itemBuilder: (context, index) {
              return attachItem(message.attach!, index, message);
            },
            itemCount: message.attach!.length,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true),
        message.msg != "" && message.msg!.isNotEmpty
            ? Card(
                elevation: 0.0,
                color: message.uid == CUR_USERID
                    ? fontColor.withOpacity(0.1)
                    : white,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5),
                  child: Column(
                    crossAxisAlignment: message.uid == CUR_USERID
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: <Widget>[
                      Text("${message.msg}",
                          style: const TextStyle(color: fontColor)),
                      Padding(
                        padding: const EdgeInsetsDirectional.only(top: 5),
                        child: Text(message.date!,
                            style: const TextStyle(
                                color: lightBlack, fontSize: 9)),
                      ),
                    ],
                  ),
                ),
              )
            : Container(),
      ],
    );
  }

  _imgFromGallery() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      files = result.paths.map((path) => File(path!)).toList();
      if (mounted) setState(() {});
    } else {}
  }

  Future<void> sendMessage(String message) async {
    setState(
      () {
        msgController.text = "";
      },
    );
    var request = http.MultipartRequest("POST", sendMsgApi);
    request.headers.addAll(headers);
    request.fields[USER_ID] = CUR_USERID!;
    request.fields[TICKET_ID] = widget.id!;
    request.fields[USER_TYPE] = USER;
    request.fields[MESSAGE] = message;

    if (files != []) {
      for (int i = 0; i < files.length; i++) {
        var pic = await http.MultipartFile.fromPath(ATTACH, files[i].path);
        request.files.add(pic);
      }
    }

    var response = await request.send();
    var responseData = await response.stream.toBytes();
    var responseString = String.fromCharCodes(responseData);
    var getdata = json.decode(responseString);
    bool error = getdata["error"];
    String? msg = getdata['message'];
    var data = getdata["data"];

    if (!error) {
      files.clear();
      insertItem(responseString);
    }
  }

  Future<void> getMsg() async {
    try {
      var data = {
        TICKET_ID: widget.id,
      };

      Response response = await post(getMsgApi, body: data, headers: headers)
          .timeout(const Duration(seconds: timeOut));

      if (response.statusCode == 200) {
        var getdata = json.decode(response.body);

        bool error = getdata["error"];
        String? msg = getdata["message"];

        if (!error) {
          var data = getdata["data"];
          chatList =
              (data as List).map((data) => Model.fromChat(data)).toList();
        }
        if (mounted) setState(() {});
      }
    } on TimeoutException catch (_) {}
  }

  msgRow() {
    return widget.status != "4" && ticketWrite
        ? Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              width: double.infinity,
              color: white,
              child: Row(
                children: <Widget>[
                  GestureDetector(
                    onTap: () {
                      _imgFromGallery();
                    },
                    child: Container(
                      height: 30,
                      width: 30,
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 15,
                  ),
                  Expanded(
                    child: TextField(
                      controller: msgController,
                      maxLines: null,
                      decoration: InputDecoration(
                          hintText: getTranslated(context, WritemessageText)!,
                          hintStyle: const TextStyle(color: lightBlack),
                          border: InputBorder.none),
                    ),
                  ),
                  const SizedBox(
                    width: 15,
                  ),
                  FloatingActionButton(
                    mini: true,
                    onPressed: () {
                      if (msgController.text.trim().isNotEmpty ||
                          files.isNotEmpty) {
                        sendMessage(msgController.text.trim());
                      }
                    },
                    backgroundColor: primary,
                    elevation: 0,
                    child: const Icon(
                      Icons.send,
                      color: white,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          )
        : Container();
  }

  Widget attachItem(List<attachment> attach, int index, Model message) {
    String? file = attach[index].media;
    String? type = attach[index].type;
    String icon;
    if (type == "video") {
      icon = "assets/images/video.png";
    } else if (type == "document") {
      icon = "assets/images/doc.png";
    } else if (type == "spreadsheet") {
      icon = "assets/images/sheet.png";
    } else {
      icon = "assets/images/zip.png";
    }

    return file == null
        ? Container()
        : Stack(
            alignment: Alignment.bottomRight,
            children: <Widget>[
              FutureBuilder<List<Directory>?>(
                future: _externalStorageDirectories,
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  return Card(
                    //margin: EdgeInsets.only(right: message.sender_id == myid ? 10 : 50, left: message.sender_id == myid ? 50 : 10, bottom: 10),
                    elevation: 0.0,
                    color: message.uid == CUR_USERID
                        ? fontColor.withOpacity(0.1)
                        : white,
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Column(
                        crossAxisAlignment: message.uid == CUR_USERID
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: <Widget>[
                          //_messages[index].issend ? Container() : Center(child: SizedBox(height:20,width: 20,child: new CircularProgressIndicator(backgroundColor: ColorsRes.secondgradientcolor,))),

                          GestureDetector(
                            onTap: () async {
                              var status = await Permission.storage.status;
                              Map<Permission, PermissionStatus> statuses =
                                  await [
                                Permission.storage,
                              ].request();
                              if (status != PermissionStatus.granted) {
                                var targetPath;

                                if (Platform.isIOS) {
                                  Directory target =
                                      await getApplicationDocumentsDirectory();
                                  _filePath = target.path.toString();
                                } else {
                                  if (snapshot.hasData) {
                                    targetPath = '/storage/emulated/0/Download';
                                    if (!await Directory(targetPath).exists()) {
                                      targetPath =
                                          await getExternalStorageDirectory();
                                    }
                                  }
                                }

                                String fileName = attach[index]
                                    .media!
                                    .substring(
                                        attach[index].media!.lastIndexOf("/") +
                                            1);
                                File file = File(targetPath + "/" + fileName);
                                bool hasExisted = await file.exists();

                                if (downloadlist.containsKey(message.id)) {
                                  final tasks = await FlutterDownloader
                                      .loadTasksWithRawQuery(
                                          query:
                                              "SELECT status FROM task WHERE task_id=${downloadlist[message.id]}");

                                  if (tasks == 4 || tasks == 5) {
                                    downloadlist.remove(message.id);
                                  }
                                }

                                if (hasExisted) {
                                  final openFile = await OpenFilex.open(
                                      "$_filePath/$fileName");
                                } else if (downloadlist
                                    .containsKey(message.id)) {
                                  setsnackbar(
                                      getTranslated(context, DownloadingText)!,
                                      context);
                                } else {
                                  setsnackbar(
                                      getTranslated(context, DownloadingText)!,
                                      context);
                                  final taskid =
                                      await FlutterDownloader.enqueue(
                                          url: attach[index].media!,
                                          savedDir: _filePath,
                                          headers: {
                                            "auth": "test_for_sql_encoding"
                                          },
                                          showNotification: true,
                                          openFileFromNotification: true);

                                  setState(
                                    () {
                                      downloadlist[message.id] =
                                          taskid.toString();
                                    },
                                  );
                                }
                              }
                              //          _requestDownload(attach[index].media, message.id);
                            },
                            child: type == "image"
                                ? Image.network(
                                    file,
                                    width: 250,
                                    height: 150,
                                    fit: BoxFit.cover,
                                  )
                                : Image.asset(
                                    icon,
                                    width: 100,
                                    height: 100,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    message.date!,
                    style: const TextStyle(
                      color: lightBlack,
                      fontSize: 9,
                    ),
                  ),
                ),
              ),
            ],
          );
  }
}
