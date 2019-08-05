import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esi_flutter_chat/screens/signin.dart';
import 'package:esi_flutter_chat/utilities/constants.dart';
import 'package:firebase_messaging/firebase_messaging.dart';


class LoginScreen extends StatefulWidget {
  LoginScreen({Key key, this.title}) : super(key: key);

  final String title;

  @override
  LoginScreenState createState() => new LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final GoogleSignIn googleSignIn = new GoogleSignIn();
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  SharedPreferences prefs;

  bool isLoading = false;
  bool isLoggedIn = false;
  FirebaseUser currentUser;
  String currentUserFCMToken;

  // for Firebase Chat Notifications
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  @override
  void initState() {
    super.initState();
    isSignedIn();
  }

  /// isSignedIn - check if user is logged in
  void isSignedIn() async {
    this.setState(() {
      isLoading = true;
    });

    prefs = await SharedPreferences.getInstance();

    isLoggedIn = await googleSignIn.isSignedIn();
    if (isLoggedIn) {
      getCurrentUserFCMToken();
      print("** isSignedIn :: fcm token ->> :: > ");
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                SignInScreen(currentUserId: prefs.getString('id'))),
      );
    } else {
      print("** isSignedIn -- isLoggedIn false");
    }

    this.setState(() {
      isLoading = false;
    });
  }

  String getCurrentUserFCMToken() {
    _firebaseMessaging.getToken().then((token){
      print("** getCurrentUserFCMToken :: fcm token ->> :: > " + token);
      return token.toString();
    }, onError: (err) {
      /// Could not get fcm token for user
      print("** getCurrentUserFCMToken :: token error");
      return null;
    });
  }

  /// Future handleSignIn - call all sign ins be handled here
  Future<Null> handleSignIn() async {
    print("** handleSignIn top");
    prefs = await SharedPreferences.getInstance();

    this.setState(() {
      isLoading = true;
    });


    // Init firebaseUser 
    FirebaseUser firebaseUser;
    try{
      /// sign in user to Google
      final GoogleSignInAccount googleUser = await googleSignIn.signIn();
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.getCredential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      firebaseUser = await firebaseAuth.signInWithCredential(credential);
      print("** handleSignIn -- signed in " + firebaseUser.displayName);
    
    } catch (e) {
      print("** exception -> ** " + e.toString());
      throw Error();
    }

    /// ******** IMPORTANT **************
    /// NOTE: On re-logins to the app the Cloudstore user -> fcmtoken is not getting updated for new devices
    /// Need a fix here in the login class to make sure that every re-login updates the fcmtoken
    if (firebaseUser != null) {
      // Check is User already signed in?
      print("** handleSignIn firebaseUser is NOT NULL");

      final QuerySnapshot result = await Firestore.instance
          .collection('users')
          .where('id', isEqualTo: firebaseUser.uid)
          .getDocuments();
      final List<DocumentSnapshot> documents = result.documents;
      if (documents.length == 0) {
        // Update data to server if new user
        print("** handleSignIn -- New user, save profile data to Firestore instance ***");
        // NOTE: Adding fcm token to user data on firestore so that cloud functions can send notifications
        _firebaseMessaging.getToken().then((token){
          print("** iOS :: fcm token ->> :: > " + token);
          Firestore.instance
              .collection('users')
              .document(firebaseUser.uid)
              .setData({
            'nickname': firebaseUser.displayName,
            'photoUrl': firebaseUser.photoUrl,
            'email': firebaseUser.email,
            'fcmtoken' : token,
            'id': firebaseUser.uid
          });
        }, onError: (err) {
          /// Could not get fcm token for user
          Fluttertoast.showToast(msg: 'User login error');
        });

        // Write data to local
        currentUser = firebaseUser;
        await prefs.setString('id', currentUser.uid);
        await prefs.setString('nickname', currentUser.displayName);
        await prefs.setString('photoUrl', currentUser.photoUrl);
        await prefs.setString('email', currentUser.email);
      } else {
        print("** handleSignIn -- User has already logged in, profile data should already be saved in Firestore ***");
        // Write data to local
        // TODO: Look into issue with About Me not updating text
        // Also may need to update fcm token on firestore database, need to make sure fcm token is always up to date
        await prefs.setString('id', documents[0]['id']);
        await prefs.setString('nickname', documents[0]['nickname']);
        await prefs.setString('photoUrl', documents[0]['photoUrl']);
        await prefs.setString('aboutMe', documents[0]['aboutMe']);
        await prefs.setString('email', documents[0]['email']);
        //await prefs.setString('fcmtoken', token);

        // TODO: Add error checking if Firestore update of token fails
        // Move into separate function
        //if(getCurrentUserFCMToken() != null) {
          print("** handleSignIn -- Update FCM Token in Firestore For User *** firebase uid -> " + firebaseUser.uid);
//          String updatedFCMToken = await getCurrentUserFCMToken();
//          if(updatedFCMToken != null) {
//            print("** handleSignIn -- Update FCM Token in Firestore For User *** updatedFCMToken :: -> " + updatedFCMToken);
//            Firestore.instance
//                .collection('users')
//                .document(firebaseUser.uid)
//                .updateData({
//              'fcmtoken': updatedFCMToken
//            });
//          }

        // getCurrentUserFCMToken is returning a null value, does await need to be used, does the return value need to be fixed?
        // returning token directly from here for now and should fix updating fcm token for users that login from multiple devices
        // NOTE: A user could login in from multiple accounts (example: Google accounts) but their fcm token would remain the same
        // See if for now this solves the multi-account login issue for FCM Tokens, will need to be refactored
        _firebaseMessaging.getToken().then((token){
          print("** handleSignIn -- Update FCM Token in Firestore For User *** updatedFCMToken :: -> " + token);
          Firestore.instance
              .collection('users')
              .document(firebaseUser.uid)
              .updateData({
            'fcmtoken': token
          });
        }, onError: (err) {
          /// Could not get fcm token for user
          print("** handleSignIn -- Error: could not get user fcm token");
        });
        //}

      }
      Fluttertoast.showToast(msg: "Sign in success");
      this.setState(() {
        isLoading = false;
      });

      print("** handleSignIn before Navigator push");
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => SignInScreen(
                  currentUserId: firebaseUser.uid,
                )),
      );
      print("** handleSignIn AFTER Navigator push");
    } else {
      print("** handleSignIn Sign In Failed");
      Fluttertoast.showToast(msg: "Sign in fail");
      this.setState(() {
        isLoading = false;
      });
    }
  }

  /// Widget build - AppBar config and User Sign In Buttons
  ///
  /// calls handleSignIn
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.title,
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: Stack(
          children: <Widget>[
            Center(
              child: FlatButton(
                  onPressed: handleSignIn,
                  child: Text(
                    'SIGN IN WITH GOOGLE',
                    style: TextStyle(fontSize: 16.0),
                  ),
                  color: Color(0xffdd4b39),
                  highlightColor: Color(0xffff7f7f),
                  splashColor: Colors.transparent,
                  textColor: Colors.white,
                  padding: EdgeInsets.fromLTRB(30.0, 15.0, 30.0, 15.0)),
            ),

            // Loading
            Positioned(
              child: isLoading
                  ? Container(
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                        ),
                      ),
                      color: Colors.white.withOpacity(0.8),
                    )
                  : Container(),
            ),
          ],
        ));
  }
}
