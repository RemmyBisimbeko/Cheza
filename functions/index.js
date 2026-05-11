const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

exports.notifyPlayerTurn = functions.firestore
    .document("rooms/{roomId}")
    .onUpdate(async (change, context) => {
      const before = change.before.data();
      const after = change.after.data();
      const roomId = context.params.roomId;

      if (before.currentPlayerIndex === after.currentPlayerIndex) return;
      if (after.status !== "playing") return;
      if (after.phase === "gameOver") return;

      const players = after.players || [];
      const currentIdx = after.currentPlayerIndex;
      const currentPlayer = players[currentIdx];
      const previousIdx = before.currentPlayerIndex;
      const previousPlayer = players[previousIdx];

      if (!currentPlayer || !previousPlayer) return;

      const userSnap = await db.collection("users").doc(currentPlayer.id).get();

      if (!userSnap.exists) return;

      const token = userSnap.data().fcmToken;
      if (!token) return;

      const message = {
        token,
        notification: {
          title: "🃏 Your Turn!",
          body: `${previousPlayer.name} just played. Your move!`,
        },
        data: {
          roomId,
          type: "your_turn",
        },
        android: {
          notification: {
            channelId: "matatu_turns",
            priority: "high",
            sound: "default",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      };

      try {
        await messaging.send(message);
        console.log(`Turn notification sent to ${currentPlayer.name}`);
      } catch (error) {
        console.error("Failed to send notification:", error);
      }
    });

exports.cleanupNotifications = functions.pubsub
    .schedule("every 24 hours")
    .onRun(async () => {
      const cutoff = new Date();
      cutoff.setDate(cutoff.getDate() - 1);

      const stale = await db
          .collection("notifications")
          .where("createdAt", "<", cutoff)
          .get();

      const batch = db.batch();
      stale.docs.forEach((doc) => batch.delete(doc.ref));
      await batch.commit();

      console.log(`Cleaned up ${stale.size} stale notifications`);
      return null;
    });
