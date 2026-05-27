# MovieBuff

A full-featured cinema booking application built with Flutter. MovieBuff enables users to browse movies and theatres, book seats, manage reservations, and access content offline. A separate admin interface provides full catalogue and booking management.

---

## Table of Contents

- [Features](#features)
- [Architecture](#architecture)
- [Technology Stack](#technology-stack)
- [Project Structure](#project-structure)
- [Data Layer](#data-layer)
- [Getting Started](#getting-started)
- [Configuration](#configuration)
- [User Roles](#user-roles)

---

## Features

**Customer**

- Register, log in, and manage a profile with photo upload
- Browse movies and theatres with a live-synced catalogue
- View movie details, trailers, and showtimes
- Book and cancel tickets with seat selection
- Save favourite movies for quick access
- Automatic offline fallback using cached and bundled data
- Dynamic light, dark, and system theme support

**Admin**

- Full CRUD management for movies, theatres, and showtimes
- View all bookings and cancellation requests
- Manage the local movie catalogue

**Device Integration**

- Real-time network connectivity monitoring with a UI banner
- GPS/location access
- Camera and gallery image selection for profile photos
- Battery information display
- Smooth animations and cinematic UI styling throughout

---

## Architecture

MovieBuff follows a layered MVC-style architecture with Provider-based state management.

```
lib/
├── core/           # App configuration, themes, constants, form validation
├── models/         # Data models
├── providers/      # State management (AuthProvider, MovieProvider, ThemeProvider, ConnectivityProvider)
├── services/       # Business logic and data access
├── screens/        # Application screens (customer and admin)
├── widgets/        # Reusable custom widgets
├── utils/          # Helper utilities
└── main.dart       # Application entry point and provider initialisation
```

Providers are hydrated before `runApp` to avoid flicker on startup. The movie catalogue loads asynchronously after the first frame to keep startup fast.

---

## Technology Stack

| Technology | Purpose |
|---|---|
| Flutter / Dart | Cross-platform mobile framework |
| Provider | Reactive state management |
| Laravel + Sanctum | Authentication backend (token-based) |
| HTTP | API and external JSON requests |
| sqflite | SQLite local database (bookings, favourites, catalogue cache) |
| SharedPreferences | Session persistence and user settings |
| connectivity_plus | Real-time network monitoring |
| geolocator | GPS/location services |
| battery_plus | Device battery information |
| image_picker | Camera and gallery access |
| carousel_slider | Movie carousel on the home screen |
| google_fonts | Custom typography |
| url_launcher | External trailer links |

---

## Project Structure

### Screens

| Screen | Description |
|---|---|
| `home_screen.dart` | Movie carousel, browsing, and navigation hub |
| `movie_details_screen.dart` | Full movie details and trailer link |
| `theatres_screen.dart` / `theatre_details_screen.dart` | Theatre listing and showtime view |
| `booking_screen.dart` | Seat selection and booking |
| `payment_screen.dart` | Payment confirmation flow |
| `my_bookings_screen.dart` | User booking history |
| `cancel_booking_screen.dart` | Booking cancellation |
| `profile_screen.dart` | Profile management and photo upload |
| `device_screen.dart` | Device capabilities (battery, GPS, connectivity) |
| `login_screen.dart` / `signup_screen.dart` | Authentication |
| `admin/*` | Admin dashboard, and CRUD screens for movies, theatres, showtimes, bookings |

### Services

| Service | Responsibility |
|---|---|
| `auth_service.dart` | Login, registration, session management via SharedPreferences |
| `api_service.dart` | HTTP client for Laravel Sanctum API |
| `local_db_service.dart` | SQLite schema and queries (bookings, favourites, cache) |
| `booking_service.dart` | Booking and cancellation logic |
| `external_movie_service.dart` | Fetches live catalogue from remote JSON |
| `movie_catalog_sync_service.dart` | Orchestrates sync: remote → SQLite cache → local asset |
| `customer_catalog_service.dart` / `admin_catalog_service.dart` | Role-specific catalogue operations |
| `device_service.dart` | Wraps geolocator, battery_plus, and connectivity APIs |
| `profile_photo_service.dart` | image_picker integration and SharedPreferences storage |

### Key Widgets

`GlassCard`, `CinematicBackground`, `ConnectivityBanner`, `MovieCard`, `CustomButton`, `CustomTextField`, `ThemeToggleButton`

---

## Data Layer

MovieBuff uses a three-tier data strategy:

```
Remote JSON (GitHub)
        |
        v
  SQLite Cache (sqflite)
        |
        v
  Bundled Asset (assets/data/external_movies.json)   <-- offline fallback
```

When the device is online, the app fetches the live catalogue from a remote JSON source and writes it to the SQLite cache. When offline, it reads from the cache, and falls back to the bundled asset if the cache is empty.

Bookings and favourites are persisted locally in SQLite. Session data and user preferences are stored in SharedPreferences.

**SQLite schema overview**

| Table | Columns |
|---|---|
| `bookings` | `id`, `server_id`, `user_email`, `movie_title`, `theatre`, `date`, `time`, `seats`, `amount`, `status`, `created_at`, `synced` |
| `favorites` | `title`, `image`, `genre`, `added_at` |
| `movie_cache` | `id`, `source`, `payload`, `fetched_at` |

---

## Getting Started

### Prerequisites

- Flutter SDK (Dart `^3.9.2`)
- Android Studio with an Android emulator or a physical device (Android API 21+)
- A running Laravel backend with Sanctum configured (optional — the app works offline without it)

### Install dependencies

```bash
flutter pub get
```

### Run the app

```bash
flutter run
```

---

## Configuration

All environment-specific values are centralised in `lib/core/config/app_config.dart`.

```dart
class AppConfig {
  // Laravel API base URL
  static const String apiBaseUrl = "http://127.0.0.1:8000/api";

  // Remote movie catalogue JSON
  static const String externalMoviesUrl =
      'https://raw.githubusercontent.com/Laksan-P/moviebuff/main/external_movies.json';

  // Bundled offline fallback
  static const String localMoviesAsset = 'assets/data/external_movies.json';

  // HTTP timeout
  static const Duration httpTimeout = Duration(seconds: 20);
}
```

**API URL by connection type**

| Setup | `apiBaseUrl` value |
|---|---|
| Android emulator (host machine) | `http://10.0.2.2:8000/api` |
| Physical device via `adb reverse` | `http://127.0.0.1:8000/api` |
| Physical device on same Wi-Fi | `http://<your-machine-LAN-IP>:8000/api` |

---

## User Roles

The app routes to different home screens based on the authenticated role.

```dart
home: auth.isLoggedIn
    ? (auth.isAdmin ? const AdminDashboardScreen() : const HomeScreen())
    : const LoginScreen(),
```

Roles are stored in SharedPreferences after authentication and cleared on logout.

---

## Repository

[github.com/Laksan-P/moviebuff](https://github.com/Laksan-P/moviebuff)