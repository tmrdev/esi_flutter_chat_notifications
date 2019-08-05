import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:esi_flutter_chat/pages/settings.dart';
import 'package:esi_flutter_chat/utilities/constants.dart';
import 'package:esi_flutter_chat/pages/chat.dart';
import 'package:esi_flutter_chat/main.dart';


class SignInScreen extends StatefulWidget {
  final String currentUserId;

  SignInScreen({Key key, @required this.currentUserId}) : super(key: key);

  @override
  State createState() => new SignInScreenState(currentUserId: currentUserId);
}

class SignInScreenState extends State<SignInScreen> {
  SignInScreenState({Key key, @required this.currentUserId});

  final String currentUserId;
  // TODO: Refactor a better way for setting these profile values
  String profileNickName = "NA";
  String currentProfilePic = "NA";
  String emailAddress = "NA";
  // for Firebase Chat Notifications
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  bool isLoading = false;
  List<Choice> choices = const <Choice>[
    const Choice(title: 'Settings', icon: Icons.settings),
    const Choice(title: 'Log out', icon: Icons.exit_to_app),
  ];

  Future<bool> onBackPress() {
    openDialog();
    return Future.value(false);
  }

  Future<Null> openDialog() async {
    switch (await showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            contentPadding:
            EdgeInsets.only(left: 0.0, right: 0.0, top: 0.0, bottom: 0.0),
            children: <Widget>[
              Container(
                color: themeColor,
                margin: EdgeInsets.all(0.0),
                padding: EdgeInsets.only(bottom: 10.0, top: 10.0),
                height: 100.0,
                child: Column(
                  children: <Widget>[
                    Container(
                      child: Icon(
                        Icons.exit_to_app,
                        size: 30.0,
                        color: Colors.white,
                      ),
                      margin: EdgeInsets.only(bottom: 10.0),
                    ),
                    Text(
                      'Exit app',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Are you sure to exit app?',
                      style: TextStyle(color: Colors.white70, fontSize: 14.0),
                    ),
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, 0);
                },
                child: Row(
                  children: <Widget>[
                    Container(
                      child: Icon(
                        Icons.cancel,
                        color: primaryColor,
                      ),
                      margin: EdgeInsets.only(right: 10.0),
                    ),
                    Text(
                      'CANCEL',
                      style: TextStyle(
                          color: primaryColor, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, 1);
                },
                child: Row(
                  children: <Widget>[
                    Container(
                      child: Icon(
                        Icons.check_circle,
                        color: primaryColor,
                      ),
                      margin: EdgeInsets.only(right: 10.0),
                    ),
                    Text(
                      'YES',
                      style: TextStyle(
                          color: primaryColor, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
            ],
          );
        })) {
      case 0:
        break;
      case 1:
        exit(0);
        break;
    }
  }

  /**
   * buildItem -
   */
  Widget buildItem(BuildContext context, DocumentSnapshot document) {
    if (document['id'] == currentUserId) {
      return Container();
    } else {
      return Container(
        child: FlatButton(
          child: Row(
            children: <Widget>[
              Material(
                child: CachedNetworkImage(
                  placeholder: Container(
                    child: CircularProgressIndicator(
                      strokeWidth: 1.0,
                      valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                    ),
                    width: 50.0,
                    height: 50.0,
                    padding: EdgeInsets.all(15.0),
                  ),
                  imageUrl: document['photoUrl'],
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.all(Radius.circular(25.0)),
                clipBehavior: Clip.hardEdge,
              ),
              new Flexible(
                child: Container(
                  child: new Column(
                    children: <Widget>[
                      new Container(
                        child: Text(
                          'Nickname: ${document['nickname']}',
                          style: TextStyle(color: primaryColor),
                        ),
                        alignment: Alignment.centerLeft,
                        margin: new EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 5.0),
                      ),
                      new Container(
                        child: Text(
                          'About me: ${document['aboutMe'] ?? 'Not available'}',
                          style: TextStyle(color: primaryColor),
                        ),
                        alignment: Alignment.centerLeft,
                        margin: new EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 0.0),
                      )
                    ],
                  ),
                  margin: EdgeInsets.only(left: 20.0),
                ),
              ),
            ],
          ),
          onPressed: () {
            Navigator.push(
                context,
                new MaterialPageRoute(
                    builder: (context) => new Chat(
                      peerId: document.documentID,
                      peerAvatar: document['photoUrl'],
                    )));
          },
          color: greyColor2,
          padding: EdgeInsets.fromLTRB(25.0, 10.0, 25.0, 10.0),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        ),
        margin: EdgeInsets.only(bottom: 10.0, left: 5.0, right: 5.0),
      );
    }
  }

  final GoogleSignIn googleSignIn = new GoogleSignIn();

  void onItemMenuPress(Choice choice) {
    // Handle Log Out action
    if (choice.title == 'Log out') {
      handleSignOut();
    } else {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => Settings()));
    }
  }

  /**
   * handleSignOut
   */
  Future<Null> handleSignOut() async {
    this.setState(() {
      isLoading = true;
    });

    await FirebaseAuth.instance.signOut();
    await googleSignIn.disconnect();
    await googleSignIn.signOut();

    this.setState(() {
      isLoading = false;
    });

    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => MyApp()),
            (Route<dynamic> route) => false);
  }

  void getProfileData() async {
    print("** getProfileData top hit");
    SharedPreferences prefs;

    String id = '';
    String nickname = '';
    String aboutMe = '';
    String photoUrl = '';
    String email = '';

    prefs = await SharedPreferences.getInstance();
    id = prefs.getString('id') ?? '';
    nickname = prefs.getString('nickname') ?? '';
    aboutMe = prefs.getString('aboutMe') ?? '';
    photoUrl = prefs.getString('photoUrl') ?? '';
    email = prefs.getString('email') ?? '';

    profileNickName = nickname;
    currentProfilePic = photoUrl;
    emailAddress = email;
    print("nick -> " + profileNickName);
    // Force refresh input
    setState(() {});
  }

  @override
  void initState() {
    print("** initState top hit");
    getProfileData();
    notificationsConfig();
  }

  ///
  /// notificationsConfig - starting out as a test method to ensure Notifications are coming through on iOS
  /// Refactor with code that should only run on iOS or Android
  /// chat.dart was using if (Platform.isIOS) iOS_Permission(); However I saw that this was executing also on Android?
  /// Find the best way that works
  ///
  /// ***** IMPORTANT ****** A test notification works by getting the APNS Device token from the following iOS method
  /// https://support.urbanairship.com/hc/en-us/articles/213492283-How-to-retrieve-device-tokens
  /// didRegisterForRemoteNotificationsWithDeviceToken (This is in FIRAuthAppDelegateProxy.m in the Firebase plugin, I unlocked the file so it will be overwritten if updated)
  ///
  /// *** All the spaces need to remove from the dumped APNS token, the PushNotifications test utility is successful in sending a test notification
  /// *** Also getting this warning in Xcode when selecting test notification:
  /// Warning: UNUserNotificationCenter delegate received call to -userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler: but the completion handler was never called.
  ///
  /// So on the FCM token side: it's token does not appear to send anything to the iPhone in the Firebase test console, something is breaking
  ///
  void notificationsConfig() {
    print("** notificationsConfig hit **");
    // Fire off Notification Permission check for iOS only, is this method also getting triggered on Android?
    if (Platform.isIOS) iOS_Permission();

    // Register push notifications for iOS and Android
    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        print("** notificationsConfig :: onMessage: $message");
        routeChatNotification(message['data']);
      },
      onLaunch: (Map<String, dynamic> message) async {
        //print("** notificationsConfig :: onLaunch: $message");
        // NOTE: Will there be any differences in configuring iOS deep linking to Chat for Notifications?
        //print("** notificationsConfig :: onLaunch: $message['data']['groupChatId']");

        routeChatNotification(message['data']);
        print("** notificationsConfig :: onLaunch: $message['data']['groupChatId']");

//        if(!message['data']['groupChatId'].isEmpty() && !message['data']['groupChatId'].isEmpty()) {
//          routeChatNotification(message['data']);
//        } else {
//          print("** error: no message data for notification");
//        }

      },
      onResume: (Map<String, dynamic> message) async {
        //print("** notificationsConfig :: onResume: $message");
        //print("** notificationsConfig :: onResume: groupChatId ->: " + message['data']['groupChatId']);

        routeChatNotification(message['data']);
        print("** notificationsConfig :: onResume: groupChatId ->: " + message['data']['groupChatId']);

//        if (!message['data']['groupChatId'].isEmpty() && !message['data']['groupChatId'].isEmpty()) {
//          routeChatNotification(message['data']);
//        } else {
//          print("** error: no message data for notification");
//        }


      },
    );

    _firebaseMessaging.getToken().then((String token) {
      if (token != null) {
        print("** notificationsConfig fcm token ->> :: > " + token);
      }
    });

  }

  /// groupChatId links the Chat to display
  /// sendAvatarURL is the avatar url for the sender of the message, see if the Chat class can handle getting the avatar url
  /// NOTE: Deep linking into the Chat is not working on iOS, need to find out why
  void routeChatNotification(message) {
    print("** routeChatNotification :: **: top -> group chat id ??? ::)> " + message['groupChatId']);
    Navigator.push(
        context,
        new MaterialPageRoute(
            builder: (context) => new Chat(
              peerId: message['groupChatId'],
              peerAvatar: message['senderAvatarURL'],
            )));
    print("** routeChatNotification :: **: after Navigator.push");
  }

  void iOS_Permission() {
    print("** iOS_permission top hit **");
    _firebaseMessaging.requestNotificationPermissions(IosNotificationSettings(sound: true, badge: true, alert: true));

    _firebaseMessaging.onIosSettingsRegistered.listen((IosNotificationSettings settings) {
      print("** iOS_permission :: Settings registered: $settings");
      if (settings.alert || settings.badge || settings.sound) {
        print("** iOS_permission :: alert|badge|sound triggered for iOS Notifications **");
        _firebaseMessaging.getToken().then((token){
          print("fcm token ->> :: > " + token);
        });
      } else {
        print("** iOS_permission :: alert|badge|sound NOT triggered for iOS Notifications **");
        _firebaseMessaging.getToken().then((token){
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    //TODO: Try adding Left Hand Nav Menu Here

    return new Scaffold(
    // *** NOTE: Added Theme support in class constructor, which is setting default background colors
    // *** Removed setting background color in AppBar here
        appBar: new AppBar(title: new Text("Flutter Chat")),
        drawer: new Drawer(
          child: new ListView(
            children: <Widget>[
              new UserAccountsDrawerHeader(
                accountEmail: new Text(emailAddress),
                accountName: new Text(profileNickName),
                currentAccountPicture: new GestureDetector(
                  child: new CircleAvatar(
                    backgroundImage: new NetworkImage(currentProfilePic),
                  ),
                  onTap: () => print("This is your current account."),
                ),
              ),
              new ListTile(
                  title: new Text("Settings"),
                  trailing: new Icon(Icons.settings),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(new MaterialPageRoute(builder: (BuildContext context) => Settings()));
                  }
              ),
              new Divider(),
              new ListTile(
                title: new Text("Logout"),
                trailing: new Icon(Icons.cloud_off),
                onTap: () => handleSignOut(),
              ),
            ],
          ),
        ),

      body: WillPopScope(
        child: Stack(
          children: <Widget>[
            // List
            Container(
              child: StreamBuilder(
                stream: Firestore.instance.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                      ),
                    );
                  } else {
                    return ListView.builder(
                      padding: EdgeInsets.all(10.0),
                      itemBuilder: (context, index) =>
                          buildItem(context, snapshot.data.documents[index]),
                      itemCount: snapshot.data.documents.length,
                    );
                  }
                },
              ),
            ),

            // Loading
            Positioned(
              child: isLoading
                  ? Container(
                child: Center(
                  child: CircularProgressIndicator(
                      valueColor:
                      AlwaysStoppedAnimation<Color>(themeColor)),
                ),
                color: Colors.white.withOpacity(0.8),
              )
                  : Container(),
            )
          ],
        ),
        onWillPop: onBackPress,
      ),
    );
  }
}

class Choice {
  const Choice({this.title, this.icon});

  final String title;
  final IconData icon;
}