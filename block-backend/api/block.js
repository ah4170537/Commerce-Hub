const {
  cert,
  getApps,
  initializeApp,
} = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { FieldValue, getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

function getFirebaseServices() {
  const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!serviceAccountJson) {
    throw new Error("FIREBASE_SERVICE_ACCOUNT_JSON is not configured.");
  }

  let serviceAccount;
  try {
    serviceAccount = JSON.parse(serviceAccountJson);
  } catch {
    throw new Error("FIREBASE_SERVICE_ACCOUNT_JSON must contain valid JSON.");
  }

  const app =
    getApps().find((candidate) => candidate.name === "[DEFAULT]") ??
    initializeApp({ credential: cert(serviceAccount) });

  return {
    auth: getAuth(app),
    firestore: getFirestore(app),
    messaging: getMessaging(app),
  };
}

function isValidUid(uid) {
  return (
    typeof uid === "string" &&
    uid.length > 0 &&
    uid.length <= 128 &&
    /^[A-Za-z0-9_-]+$/.test(uid)
  );
}

function errorCode(error) {
  return typeof error?.code === "string" ? error.code : "unknown";
}

function isInvalidIdTokenError(error) {
  return [
    "auth/argument-error",
    "auth/id-token-expired",
    "auth/id-token-revoked",
    "auth/invalid-id-token",
    "auth/user-disabled",
    "auth/user-not-found",
  ].includes(errorCode(error));
}

module.exports = async function handler(req, res) {
  if (req.method !== "POST") {
    res.setHeader("Allow", "POST");
    return res.status(405).json({ error: "Method not allowed." });
  }

  const authorization = req.headers.authorization;
  if (
    typeof authorization !== "string" ||
    !authorization.startsWith("Bearer ")
  ) {
    return res.status(401).json({ error: "A Firebase ID token is required." });
  }

  const body = req.body;
  if (!body || typeof body !== "object" || Array.isArray(body)) {
    return res.status(400).json({ error: "A JSON request body is required." });
  }

  const { accountType, uid } = body;
  if (accountType !== "customer" && accountType !== "rider") {
    return res
      .status(400)
      .json({ error: "accountType must be customer or rider." });
  }
  if (!isValidUid(uid)) {
    return res.status(400).json({ error: "A valid target uid is required." });
  }

  try {
    const { auth, firestore, messaging } = getFirebaseServices();
    let admin;
    try {
      admin = await auth.verifyIdToken(authorization.slice(7), true);
    } catch (error) {
      if (!isInvalidIdTokenError(error)) throw error;
      return res
        .status(401)
        .json({ error: "The Firebase ID token is invalid or expired." });
    }

    if (admin.admin !== true) {
      return res.status(403).json({ error: "Administrator access is required." });
    }
    if (admin.uid === uid) {
      return res.status(400).json({ error: "Administrators cannot block themselves." });
    }

    const collectionName = accountType === "rider" ? "riders" : "users";
    const accountRef = firestore.collection(collectionName).doc(uid);
    const accountSnapshot = await accountRef.get();
    if (!accountSnapshot.exists) {
      return res.status(404).json({ error: "The target account was not found." });
    }

    try {
      await auth.getUser(uid);
    } catch (error) {
      if (errorCode(error) === "auth/user-not-found") {
        return res
          .status(404)
          .json({
            error: "The target Firebase Authentication user was not found.",
          });
      }
      throw error;
    }

    const fcmToken = accountSnapshot.get("fcmToken");

    await accountRef.update({
      isBlocked: true,
      blockedAt: FieldValue.serverTimestamp(),
      blockedBy: admin.uid,
    });

    let authDisabled = false;
    let refreshTokensRevoked = false;
    try {
      await auth.updateUser(uid, { disabled: true });
      authDisabled = true;
      await auth.revokeRefreshTokens(uid);
      refreshTokensRevoked = true;
    } catch (error) {
      console.error("Could not fully block Firebase Authentication account.", {
        accountType,
        uid,
        code: errorCode(error),
      });
      return res.status(502).json({
        error:
          "The Firestore block was saved, but Firebase Authentication could not be fully restricted. Retry the request.",
        firestoreBlocked: true,
        authDisabled,
        refreshTokensRevoked,
      });
    }

    let notification = { sent: false, reason: "fcm_token_missing" };
    if (typeof fcmToken === "string" && fcmToken.trim().length > 0) {
      try {
        const messageId = await messaging.send({
          token: fcmToken,
          notification: {
            title: "Account blocked",
            body: "Your account has been blocked. Contact support for help.",
          },
          data: {
            type: "account_blocked",
            accountType,
          },
        });
        notification = { sent: true, messageId };
      } catch (error) {
        console.error("Could not send account-blocked FCM notification.", {
          accountType,
          uid,
          code: errorCode(error),
        });
        notification = {
          sent: false,
          reason: "fcm_send_failed",
          code: errorCode(error),
        };
      }
    }

    return res.status(200).json({
      blocked: true,
      accountType,
      uid,
      authDisabled,
      refreshTokensRevoked,
      notification,
    });
  } catch (error) {
    console.error("Block endpoint failed.", error);
    return res.status(500).json({ error: "The account could not be blocked." });
  }
};
