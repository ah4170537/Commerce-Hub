# commerce_hub

A new Flutter project.

## Product image uploads

Product images are uploaded to ImgBB; Firestore stores the resulting URLs.
Create a local `.env` file in the project root containing:

```dotenv
IMGBB_API_KEY=your_imgbb_api_key
```

The `.env` file is git-ignored and loaded by the app. Flutter bundles declared
assets into the application, so this does not keep the key secret from someone
who can inspect the built app. For a publicly distributed production app,
proxy ImgBB uploads through a trusted backend to avoid exposing the API key.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
