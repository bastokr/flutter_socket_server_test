import 'dart:io';

import 'package:flutter/material.dart';

var payIP = "192.168.0.71";
var payPort = 8002;

class SocketServer extends StatefulWidget {
  const SocketServer({super.key});

  @override
  State<SocketServer> createState() => _SocketServerState();
}

class _SocketServerState extends State<SocketServer> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  List<MessageItem> items = [];

  String localIP = "";

  late ServerSocket? serverSocket = null;
  late Socket? clientSocket = null;

  TextEditingController msgCon = TextEditingController();
  @override
  void initState() {}

  @override
  void dispose() {
    stopServer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    getIP();
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(title: Text("Socket Server")),
      body: Column(
        children: <Widget>[
          ipInfoArea(),
          messageListArea(),
          submitArea(),
        ],
      ),
    );
  }

  Widget ipInfoArea() {
    return Card(
      child: ListTile(
        dense: true,
        leading: Text("IP"),
        title: Text(localIP),
        trailing: OutlinedButton(
          onPressed: (serverSocket == null) ? startServer : stopServer,
          child: Text((serverSocket == null) ? "Start" : "Stop"),
        ),
      ),
    );
  }

  Widget messageListArea() {
    return Expanded(
      child: ListView.builder(
          reverse: true,
          itemCount: items.length,
          itemBuilder: (context, index) {
            MessageItem item = items[index];
            return Container(
              alignment: (item.owner == localIP)
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: (item.owner == localIP)
                        ? Colors.blue[100]
                        : Colors.grey[200]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      (item.owner == localIP) ? "Server" : "Client",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextFormField(
                      maxLines: 4,
                      initialValue: item.content,
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ),
            );
          }),
    );
  }

  Widget submitArea() {
    return Card(
      child: ListTile(
        title: TextField(
          controller: msgCon,
        ),
        trailing: IconButton(
          icon: Icon(Icons.send),
          color: Colors.blue,
          disabledColor: Colors.grey,
          onPressed: (clientSocket != null) ? submitMessage : null,
        ),
      ),
    );
  }

  void getIP() async {
    var ip = payIP;
    setState(() {
      localIP = ip;
    });
  }

  void startServer() async {
    print(serverSocket);
    serverSocket =
        await ServerSocket.bind(InternetAddress.anyIPv4, payPort, shared: true);
    print(serverSocket);
    serverSocket?.listen(handleClient);
    setState(() {});
  }

  void handleClient(Socket client) {
    clientSocket = client;

    showSnackBarWithKey(
        "A new client has connected from ${clientSocket!.remoteAddress.address}:${clientSocket!.remotePort}");

    clientSocket!.listen(
      (onData) {
        print(List<int>.from(onData));
        setState(() {
          items.insert(
              0,
              MessageItem(
                  clientSocket!.remoteAddress.address, onData.toString()));
        });
      },
      onError: (e) {
        showSnackBarWithKey(e.toString());
        disconnectClient();
      },
      onDone: () {
        showSnackBarWithKey("Connection has terminated.");
        disconnectClient();
      },
    );
  }

  void stopServer() {
    disconnectClient();
    serverSocket?.close();
    setState(() {
      serverSocket = null;
    });
  }

  void disconnectClient() {
    if (clientSocket != null) {
      clientSocket!.close();
      clientSocket!.destroy();
    }
  }

  void submitMessage() {
    if (msgCon.text.isEmpty) return;
    setState(() {
      items.insert(0, MessageItem(localIP, msgCon.text));
    });
    sendMessage(msgCon.text);
    msgCon.clear();
  }

  void sendMessage(String message) {
    clientSocket!.write("$message\n");
  }

  showSnackBarWithKey(String message) {}
}

class MessageItem {
  String owner;
  String content;

  MessageItem(this.owner, this.content);
}
