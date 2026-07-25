# Flutter LMS - Learning Management System

A full-featured Learning Management System (LMS) mobile application built with Flutter, connected to a Node.js/MongoDB backend via Docker.

## Tech Stack

- **Frontend:** Flutter (Dart) with Material 3 Design
- **State Management:** Provider (`ChangeNotifierProvider`)
- **HTTP Client:** Dio with JWT token interceptors
- **Backend:** Node.js REST API (Docker container)
- **Database:** MongoDB Atlas
- **Authentication:** JWT (Access + Refresh tokens)
- **Secure Storage:** `flutter_secure_storage` for token persistence
- **Typography:** Google Fonts (Outfit)

## Features

### Authentication
- Student & Instructor registration with OTP email verification
- Login with JWT-based authentication
- Automatic token refresh on 401 errors
- Splash screen with animated fade-in

### Role-Based Dashboards
- **Admin** — Create courses, manage platform
- **Instructor** — Manage courses, add sections & lessons
- **Student** — Browse courses, request enrollment, view lessons

### Student Features
- Bottom Navigation Bar (Home, Assignments, Profile)
- Course browsing with enrollment request system
- Assignment list with Pending / Submitted status indicators
- File upload for assignment submissions (PDF, DOCX, ZIP)
- Responsive layout: 2-column grid on tablets, single column on phones

### Profile Management
- View profile details (name, email, role, status)
- Edit Profile button with bottom sheet form
- Enrolled courses count
- Logout functionality

### UI/UX
- Reusable widgets (`AppButton`, `AppCard`, `SectionHeader`)
- Smooth animations (`AnimatedOpacity`, `AnimatedSwitcher`, `AnimatedContainer`)
- Responsive design using `MediaQuery` and `LayoutBuilder`
- Material 3 color scheme with custom theme

## Project Structure

```
lib/
├── main.dart
├── core/
│   ├── config/
│   │   └── app_config.dart          # API base URL (dynamic per platform)
│   ├── network/
│   │   ├── api_client.dart          # Dio client with auth interceptor
│   │   └── api_exception.dart       # Unified error handling
│   └── storage/
│       └── token_storage.dart       # Secure token persistence
├── features/
│   ├── auth/
│   │   ├── screens/                 # Login, Sign Up, OTP, Splash, Onboarding
│   │   └── services/
│   │       └── auth_service.dart    # Auth API calls
│   ├── admin/
│   │   ├── dashboard/screens/       # Admin Dashboard
│   │   └── courses/screens/         # Course Creation
│   ├── instructor/
│   │   ├── dashboard/screens/       # Instructor Dashboard
│   │   └── courses/screens/         # Course Manager
│   ├── student/
│   │   ├── student_main_screen.dart # Bottom Navigation wrapper
│   │   ├── dashboard/screens/       # Course list (Home tab)
│   │   ├── assignments/screens/     # Assignment list & submission
│   │   └── courses/screens/         # Course content viewer
│   └── profile/
│       └── screens/                 # Student & Instructor profiles
├── shared/
│   ├── models/                      # User, Course, AuthSession models
│   ├── providers/                   # AuthProvider, CourseProvider
│   ├── services/                    # CourseService
│   └── widgets/                     # AppButton, AppCard, SectionHeader
└── theme/
    └── app_theme.dart               # Material 3 theme configuration
```

## Setup Instructions

### Prerequisites
- Flutter SDK (3.x or later)
- Android Studio with Android Emulator
- Docker Desktop
- Postman (optional, for API testing)

### 1. Start the Backend
```bash
docker run -d -p 5000:5000 --name flutter-lms-backend dckuma/flutter-lms-backend:v1.0.0
```
Verify: Open `http://localhost:5000` in your browser.

### 2. Run the Flutter App
```bash
flutter pub get
flutter run
```

### Network Configuration
| Platform          | Backend URL              |
|-------------------|--------------------------|
| Android Emulator  | `http://10.0.2.2:5000`   |
| Chrome / Web      | `http://localhost:5000`   |
| Physical Device   | `http://<your-ip>:5000`  |

The app automatically detects the platform and uses the correct URL.

### 3. Test with Postman
Import `Flutter LMS Backend API.json` into Postman. Use `http://localhost:5000/api/v1` as the base URL.

## Screenshots

_Screenshots to be added after final testing._

## License

This project is part of an internship assignment.
