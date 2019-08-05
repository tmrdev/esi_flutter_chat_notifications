import 'package:flutter/material.dart';
import 'package:esi_flutter_chat/utilities/constants.dart';

import 'package:esi_flutter_chat/screens/chat.dart';

class Chat extends StatelessWidget {
  final String peerId;
  final String peerAvatar;

  Chat({Key key, @required this.peerId, @required this.peerAvatar}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(
          'Chat',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: new ChatScreen(
        peerId: peerId,
        peerAvatar: peerAvatar,
      ),
      
    );
  }

  List<Widget> _buildsTabs() {
  return <Widget>[
    Tab(text: "Groups"),
    Tab(text: "Contacts"),
    ];
  }

}