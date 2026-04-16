# MiCampus

A Flutter app for discovering, creating, and managing campus events. Connect with your community, showcase events, sign up as a volunteer, and design event posters—all in one place.

## Features

- **Onboarding** — Welcome screens introducing campus events, talent showcase, and tech & innovation
- **Auth** — Sign up, login, OTP verification, and forgot password
- **Explore** — Browse events with category filters (IT/Tech, Cultural, Sports, Academic, Social), carousel banners, and event details
- **My Events** — View events you’re attending or have created
- **Create Event** — Add new events with details, date, venue, and poster
- **Poster Editor** — Choose templates and customize event posters; export as image or PDF and save to gallery
- **Favorites** — Save and manage favorite events
- **Volunteers** — Sign up for volunteer roles (Stage Manager, Tech Support, Crowd Management, Registration, Catering, Decoration, Photography, etc.)
- **Profile** — View and edit profile, manage account

## Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install) (SDK >=3.0.0 <4.0.0)
- Android Studio / Xcode (for mobile) or VS Code with Flutter extension

## Getting Started

### 1. Clone and install

```bash
git clone <repository-url>
cd campus_social
flutter pub get
```

### 2. Run the app

```bash
# Run on connected device or emulator
flutter run

# Run on a specific device
flutter devices
flutter run -d <device_id>
```

### 3. Build release

```bash
# Android APK
flutter build apk

# Android App Bundle (for Play Store)
flutter build appbundle

# iOS
flutter build ios
```

## Project Structure

```
lib/
├── base/
│   └── constant.dart          # API URLs, colors, categories, volunteer roles
├── controllers/
│   ├── auth_controller.dart
│   ├── create_event_controller.dart
│   ├── event_controller.dart
│   ├── poster_controller.dart
│   └── profile_controller.dart
├── data/
│   ├── api_service.dart       # HTTP/API calls
│   ├── otp_service.dart
│   └── pref_service.dart      # SharedPreferences
├── modal/
│   ├── model_event.dart
│   └── model_user.dart
├── views/
│   ├── splash_view.dart       # Onboarding
│   ├── login_view.dart
│   ├── signup_view.dart
│   ├── otp_verification_view.dart
│   ├── forgot_password_view.dart
│   ├── home_view.dart         # Explore / My Events / Profile tabs
│   ├── event_detail_view.dart
│   ├── create_event_view.dart
│   ├── poster_editor_view.dart
│   ├── template_gallery_view.dart
│   ├── favorites_view.dart
│   ├── edit_profile_view.dart
│   └── volunteer_dialog.dart
├── widgets/
│   ├── event_banner_theme.dart
│   └── poster_themes.dart
└── main.dart
```

## Tech Stack

| Area | Choice |
|------|--------|
| Framework | Flutter |
| State management & routing | GetX |
| HTTP | Dio, http |
| Local storage | shared_preferences, path_provider |
| UI | Material 3, flutter_screenutil, Google Fonts |
| Media | image_picker, carousel_slider, pdf, saver_gallery, permission_handler |
| OTP UI | pin_code_fields |
| Date/time | intl |

## Configuration

- **API base URL** is set in `lib/base/constant.dart` (`baseUrl`). Update it if your backend is hosted elsewhere.
- **Launcher icon** is configured in `pubspec.yaml` via `flutter_launcher_icons` (image: `assets/icon/logo.jpeg`).

## Assets

Images and icons live under `assets/images/` and `assets/icon/`. Ensure all paths referenced in `pubspec.yaml` exist. Run `flutter pub get` after adding or changing assets.

## License

This project is not published to pub.dev (`publish_to: 'none'`). Use according to your organization’s terms.
