import { initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { onCall, HttpsError } from "firebase-functions/v2/https";

export { askQuestCoach } from "./questCoach.js";

initializeApp();
const db = getFirestore();

export const completeToday = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in first.");
  }

  if (request.data?.challengeId !== "today") {
    throw new HttpsError("invalid-argument", "Unknown challenge.");
  }

  const uid = request.auth.uid;
  const progressRef = db.doc(`users/${uid}/progress/today`);

  return db.runTransaction(async (transaction) => {
    const progress = await transaction.get(progressRef);

    if (progress.exists) {
      const saved = progress.data();
      return {
        completed: true,
        points: saved.points,
        badgeId: saved.badgeId,
        alreadyCompleted: true,
      };
    }

    const challenge = await transaction.get(db.doc("challenges/today"));
    const quest = challenge.data();

    if (
      typeof quest?.title !== "string" ||
      !quest.title.trim() ||
      typeof quest?.prompt !== "string" ||
      !quest.prompt.trim()
    ) {
      throw new HttpsError(
        "failed-precondition",
        "Today's challenge is unavailable.",
      );
    }

    const reward = {
      completed: true,
      points: 10,
      badgeId: "first-quest",
      completedAt: FieldValue.serverTimestamp(),
    };

    transaction.set(progressRef, reward);

    return {
      completed: true,
      points: reward.points,
      badgeId: reward.badgeId,
      alreadyCompleted: false,
    };
  });
});