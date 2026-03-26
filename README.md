# Fluense Flutter App

MR management app for Fluense Pharma. Built with Flutter + Next.js backend.

---

## Project Structure

```
lib/
├── main.dart                        # App entry point
├── config/
│   ├── app_config.dart              # API base URL, product list
│   └── app_theme.dart               # Colors, typography, component styles
├── models/
│   ├── user_model.dart
│   ├── client_model.dart
│   ├── attendance_model.dart
│   ├── visit_model.dart
│   └── goal_model.dart
├── services/
│   ├── api_service.dart             # All HTTP calls to Next.js backend
│   └── location_service.dart        # GPS / geolocator wrapper
├── providers/
│   └── auth_provider.dart           # Login, logout, current user state
├── screens/
│   ├── splash_screen.dart           # Auth check on launch
│   ├── auth/
│   │   └── login_screen.dart
│   ├── home/
│   │   └── home_screen.dart         # Dashboard + bottom nav
│   ├── clients/
│   │   ├── client_list_screen.dart  # Doctor/Retailer/Stockist tabs
│   │   └── client_detail_screen.dart # Map, About, History, actions
│   ├── visits/
│   │   ├── visit_logger_screen.dart # Check-in/out, products, collaborator
│   │   ├── product_detail_sheet.dart # Per-product explained/available/remarks
│   │   └── report_log_screen.dart   # Daily visit history
│   └── profile/
│       └── profile_screen.dart      # User info + attendance history
└── widgets/
    ├── home_stat_card.dart
    ├── section_header.dart
    ├── info_tile.dart
    ├── loading_button.dart
    └── empty_state.dart
```

---

## Setup

### 1. Install dependencies

```bash
flutter pub get
```

### 2. Configure backend URL

Open `lib/config/app_config.dart` and set your Next.js backend URL:

```dart
static const String baseUrl = 'https://your-backend.vercel.app/api';
// or for local development:
// static const String baseUrl = 'http://10.0.2.2:3000/api';  // Android emulator
// static const String baseUrl = 'http://localhost:3000/api';  // iOS simulator
```

### 3. Google Maps (optional but recommended)

Get a Google Maps API key from [Google Cloud Console](https://console.cloud.google.com/).

**Android:** Replace `YOUR_MAPS_API_KEY` in `android/app/src/main/AndroidManifest.xml`

**iOS:** Replace `YOUR_MAPS_API_KEY` in `ios/Runner/Info.plist`

Then in `client_detail_screen.dart`, replace the placeholder map section with:

```dart
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Replace _buildMapSection with:
SizedBox(
  height: 200,
  child: GoogleMap(
    initialCameraPosition: CameraPosition(
      target: LatLng(client.lat!, client.lng!),
      zoom: 15,
    ),
    markers: {
      Marker(
        markerId: const MarkerId('client'),
        position: LatLng(client.lat!, client.lng!),
      ),
    },
    zoomControlsEnabled: false,
    myLocationButtonEnabled: false,
  ),
),
```

### 4. Run the app

```bash
# Android
flutter run

# iOS
flutter run -d ios

# Release build
flutter build apk --release
flutter build ios --release
```

---

## Required Next.js API Endpoints

The app expects these endpoints on your backend:

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/login` | Login → returns `{ token, user }` |
| GET | `/api/auth/me` | Get current user from token |
| GET | `/api/attendance?mrId=&date=` | Get today's attendance |
| POST | `/api/attendance/checkin` | Check in with location |
| POST | `/api/attendance/checkout` | Check out with location |
| GET | `/api/attendance?mrId=&limit=` | Attendance history |
| GET | `/api/clients?regionId=&type=` | List clients by region/type |
| GET | `/api/clients/:id` | Single client detail |
| GET | `/api/visits?mrId=&date=` | Today's visits |
| GET | `/api/visits?clientId=&limit=` | Client visit history |
| POST | `/api/visits/start` | Start a visit (check-in) |
| PATCH | `/api/visits/:id/end` | End a visit (check-out + products) |
| GET | `/api/goals?mrId=&date=` | Today's goal |
| GET | `/api/users?regionId=&role=mr` | MRs in a region |

---

## Notes

- **Light mode only** — matches Figma design
- **MRs can only change profile picture** — admins control all other fields
- **Soft delete** — deleting a client/MR sets status to `inactive`, not hard delete
- Products list is static in `app_config.dart` — update as needed
- Token is stored securely via `flutter_secure_storage`
