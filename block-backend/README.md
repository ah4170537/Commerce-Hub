# Account blocking API

This is a Vercel Node.js Function for blocking Commerce Hub customers and
riders. Deploy this directory as the Vercel project's root directory.

## Endpoint

`POST /api/block`

Headers:

```text
Authorization: Bearer <Firebase ID token for an administrator>
Content-Type: application/json
```

Body:

```json
{
  "accountType": "rider",
  "uid": "target-firebase-auth-uid"
}
```

Use `"customer"` for customers. The endpoint only accepts an authenticated
Firebase user with the `admin: true` custom claim. It updates the target
document in `riders` or `users` with `isBlocked`, `blockedAt`, and `blockedBy`,
disables the corresponding Firebase Authentication account, revokes its refresh
tokens, and attempts an FCM notification.

A successful block response includes `notification.sent`. If the target has no
`fcmToken`, the account is still blocked and the response reports
`notification.reason: "fcm_token_missing"`.

## Deploying to Vercel

1. Push this directory to GitHub. It can be in its own repository or alongside
   the app; if alongside the app, set Vercel's **Root Directory** to
   `block-backend`.
2. Import the repository in Vercel as a Node.js project.
3. In Vercel project settings, add the environment variable
   `FIREBASE_SERVICE_ACCOUNT_JSON` for the Production environment (and Preview
   if needed). Its value must be the full JSON of a Firebase service-account
   key with permissions to manage Firebase Authentication, Firestore, and FCM.
   Create the key in Firebase/Google Cloud service-account settings. Never
   commit this JSON file or put the key in app code.
4. Deploy, then verify that `GET <deployment-url>/api/block` returns HTTP 405.
5. The production endpoint will be
   `https://<deployment-domain>/api/block`.

The customer app currently stores its token at `users/{uid}.fcmToken`. The
rider app does not currently register an FCM token, so rider blocking and
account disabling will work, but a rider push notification will not be sent
until FCM token registration is added to that app.

The client apps must also check `isBlocked` and sign the account out or prevent
access when it is true. The rider app already checks this field; customer-app
enforcement and the admin dashboard's API integration are follow-up steps.
