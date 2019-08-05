'use strict';
// The Cloud Functions for Firebase SDK to create Cloud Functions and setup triggers.
const functions = require('firebase-functions');
// The Firebase Admin SDK to access the Firebase Realtime Database.
const admin = require('firebase-admin');
//admin.initializeApp();
admin.initializeApp(functions.config().firebase);
// docs:
// https://firebase.google.com/docs/cloud-messaging/concept-options
// https://firebase.google.com/docs/cloud-messaging/send-message (with topic configuration)
exports.sendNotifications = functions.firestore.document('messages/{messageId}/{subMessageId}/{documentId}').onWrite(
  async (change, context) => {
    const messageId = context.params.messageId;
    // NOTE: There is a before and after for data that is in the process of getting updated, tied to onWrite function
    const updatedMessageData = change.after.data();
    // NOTE: Set key object values in a constant or var first, do not try to use them like updatedMessageData["idTo"]
    const myIdTo = updatedMessageData["idTo"];
    const myIdFrom = updatedMessageData["idFrom"];
    const messageText = updatedMessageData["content"];
    const messageKeys = Object.keys(updatedMessageData)

    // See if messageId is the same as groupChatId in Chat class, then pass this key into the notification and try to get the Chat class
    console.log("sendNotifications has been triggered - messages have updated with onWrite myDocument Id -> " + messageId + " : " + messageKeys + " : " + myIdTo);
    const messageReceiverToken = await getTokenForReceiverNotification(myIdTo);
    const messageRecieverSenderAvatar = await getSenderAvatarForReceiverNotification(myIdFrom);
    console.log(" receiver token -> " + messageReceiverToken + " : photo url -> " + messageRecieverSenderAvatar);

    var payload = {
      notification: {
        title: 'Chat Message',
        body: messageText,
        icon: 'default',
        sound: 'default'
      },
      data: {
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
        groupChatId: messageId,
        senderAvatarURL: messageRecieverSenderAvatar,
        category: 'default'
      }
    };

    // NOTE: On re-logins to the app the Cloudstore user -> fcmtoken is not getting updated for new devices
    // Need a fix on the Flutter mobile code to make sure that every re-login updates the fcmtoken
    var tokens = messageReceiverToken;
    const response = await admin.messaging().sendToDevice(tokens, payload);
    console.log('Notifications have been sent');
  });

  // This Promise returns the fcm token that is used to send chat notifications to relevant users
  // This function provides a good example for returning data with the proper else and catch statements
  // make sure all calls have these catches
  function getTokenForReceiverNotification(userTokenDocId) {
    console.log("getTokenForReceiverNotification top hit user doc id -> " + userTokenDocId);
    var userTokenRef = admin.firestore().collection('users').doc(userTokenDocId);
    return userTokenRef
      .get()
      .then(doc => {
        if (!doc.exists) {
          console.log('No such User document!');
          throw new Error('No such User document!'); //should not occur normally as the notification is a "child" of the user
        } else {
          console.log('Document data:', doc.data());
          console.log('Document data:', doc.data().fcmtoken);
          var fcmToken = doc.data().fcmtoken;
          return fcmToken;
        }
      })
      .catch(err => {
        console.log('Error getting document', err);
        return false;
      });
  }

  function getSenderAvatarForReceiverNotification(userDocId) {
    console.log("getSenderAvatarForReceiverNotification top hit user doc id -> " + userDocId);
    var userRef = admin.firestore().collection('users').doc(userDocId);
    return userRef
      .get()
      .then(doc => {
        if (!doc.exists) {
          console.log('No such User document!');
          throw new Error('No such User document!'); //should not occur normally as the notification is a "child" of the user
        } else {
          console.log('Document data:', doc.data());
          console.log('Document data:', doc.data().photoUrl);
          var photoUrl = doc.data().photoUrl;
          return photoUrl;
        }
      })
      .catch(err => {
        console.log('Error getting document', err);
        return false;
      });
  }