const { setGlobalOptions } = require("firebase-functions/v2");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

setGlobalOptions({
  maxInstances: 10,
});

exports.sendChatNotification = onDocumentCreated(
  "chats/{chatId}/messages/{messageId}",
  async (event) => {
    try {
      const snapshot = event.data;

      if (!snapshot) {
        console.log("No snapshot data");
        return;
      }

      const message = snapshot.data();

      const senderId = message.senderId;
      const receiverId = message.receiverId;
      const text = message.text || "New Message";
      const chatId = event.params.chatId;

      console.log("New message detected");
      console.log(message);

      // Get receiver profile
      const userDoc = await admin
        .firestore()
        .collection("users")
        .doc(receiverId)
        .get();

      if (!userDoc.exists) {
        console.log("Receiver not found");
        return;
      }

      const userData = userDoc.data();

      // IMPORTANT CONDITIONS

      // 1. Logged out user → no notification
      if (!userData.isOnline) {
        console.log("User offline/logged out");
        return;
      }

      // 2. Same chat open → no notification
      if (userData.activeChatId === chatId) {
        console.log("User already viewing chat");
        return;
      }

      const token = userData.fcmToken;

      if (!token) {
        console.log("No FCM token");
        return;
      }

      // Sender info
      const senderDoc = await admin
        .firestore()
        .collection("users")
        .doc(senderId)
        .get();

      const senderData = senderDoc.data();

      const senderName =
        senderData?.name ||
        senderData?.email ||
        "New Message";

      // Notification payload
      const payload = {
        token: token,

        notification: {
          title: senderName,
          body: text,
        },

        data: {
          chatId: chatId,
          senderId: senderId,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },

        android: {
          priority: "high",
          notification: {
            channelId: "chat_messages",
            priority: "high",
            defaultSound: true,
          },
        },

        apns: {
          payload: {
            aps: {
              sound: "default",
            },
          },
        },

        webpush: {
          notification: {
            title: senderName,
            body: text,
            icon: "/favicon.png",
          },
          fcmOptions: {
            link: `/chat/${chatId}`,
          },
        },
      };

      const response = await admin.messaging().send(payload);

      console.log("Notification sent successfully");
      console.log(response);

      return response;
    } catch (error) {
      console.error("Notification Error:", error);
      return null;
    }
  }
);