# MovieBuff — MAD II Report Support Document

**Module:** Mobile Application Development II (MAD II)  
**Application:** MovieBuff — Flutter Android Cinema Booking Application  
**Document purpose:** Professional report content aligned with the current MovieBuff implementation (no placeholder text).

---

## 1. Introduction

MovieBuff is a **Flutter-based Android mobile application** developed for cinema ticket discovery, seat selection, and booking management. The application serves two primary user roles: **customers**, who browse movies, select showtimes, book seats, and manage personal bookings; and **administrators**, who manage movies, theatres, and showtimes through a dedicated control centre.

The application integrates with a **Laravel SSP (Sanctum) REST API** for authentication when the backend is reachable, while retaining a **local authentication fallback** using SharedPreferences so that demonstration and offline scenarios remain functional. Movie catalogue data is sourced from an **external JSON master list** hosted on GitHub (`external_movies.json`), with a layered offline strategy: live network fetch, **sqflite cache**, and a **bundled asset fallback**.

MovieBuff demonstrates **mobile device capabilities** required for MAD II, including network connectivity monitoring, geolocation for nearest-cinema suggestions, battery status reporting, and camera/gallery profile photo capture stored per user on the device. The UI follows a **premium cinematic Material 3** design with **light, dark, and system theme** support.

Customer navigation uses a bottom tab structure (Home, Theatres, Bookings, Device, Profile). Administrators are routed to the **Admin Dashboard** after login when the authenticated account has an admin role.

---

## 4. Objectives of the Application

The primary objectives of the MovieBuff application are:

1. **Provide a complete customer cinema experience** — browse a live or cached movie catalogue, view movie and theatre details, select showtimes, choose seats, and complete a simulated payment flow.
2. **Integrate SSP API authentication** — authenticate users via Laravel Sanctum token endpoints with secure local session persistence and graceful fallback when the API is unavailable.
3. **Consume external JSON as the master movie catalogue** — fetch, cache, and merge external movie data for customer and admin views, with offline resilience.
4. **Persist user-specific data locally** — store bookings, favourites, profile details, and profile photos on the device using sqflite and SharedPreferences.
5. **Support administrative catalogue management** — enable CRUD operations for movies, theatres, and showtimes with synchronization to the customer-facing catalogue through merge services.
6. **Demonstrate native mobile capabilities** — connectivity awareness, GPS-based nearest cinema lookup, battery monitoring, and profile image capture from camera or gallery.
7. **Deliver a polished, accessible UI** — responsive layouts for small devices, theme-aware components, and smooth navigation without altering core business logic during UI refinement.

---

## 5. Technologies Used

| Technology | Purpose in MovieBuff |
|------------|----------------------|
| **Flutter** | Cross-platform UI framework used to build the Android MovieBuff application with Material widgets, navigation, and responsive layouts. |
| **Dart** | Primary programming language for application logic, services, providers, and validation. |
| **Provider** | State management via `ChangeNotifier` providers (`AuthProvider`, `MovieProvider`, `ConnectivityProvider`, `ThemeProvider`) to decouple UI from data and notify widgets on changes. |
| **Laravel SSP** | Backend Student Software Project API providing registration, login, and logout endpoints consumed by `ApiService`. |
| **Sanctum Authentication** | Token-based API authentication; Bearer tokens are stored in SharedPreferences and attached to authenticated requests. |
| **sqflite** | Local SQLite database (`moviebuff.db`) for favourites, external JSON cache snapshots, and customer booking records. |
| **SharedPreferences** | Lightweight key-value storage for user sessions, Sanctum tokens, theme preference, admin/customer movie and theatre seeds, profile photos (per user), and legacy booking JSON. |
| **connectivity_plus** | Monitors Wi-Fi, mobile data, and offline states; drives the connectivity banner and Device screen network status. |
| **geolocator** | Reads device GPS or last-known location to suggest the nearest Sri Lankan cinema venue on the Device screen. |
| **battery_plus** | Reports battery percentage and charging state on the Device screen. |
| **image_picker** | Captures profile photos from the device camera or photo gallery (invoked from the Profile screen). |
| **Material 3** | Theming via `AppTheme` with light/dark colour schemes, cinematic cards, and accessible form components. |
| **GitHub Raw JSON** | Hosts the master `external_movies.json` catalogue fetched at runtime from the configured raw GitHub URL in `AppConfig`. |

**Additional supporting packages (implementation):** `http` (REST and JSON fetch), `google_fonts`, `carousel_slider`, `path_provider`, `url_launcher`, and `flutter_launcher_icons` (application icon generation).

---

## 6. System Architecture / MVC Structure

MovieBuff follows a **layered architecture** that separates presentation, state, business logic, and persistence. Although Flutter does not enforce classical MVC strictly, the project maps cleanly to an **MVC-inspired structure**:

```
┌─────────────────────────────────────────────────────────┐
│                    UI Layer (Screens / Widgets)          │
│  login_screen, home_screen, booking_screen, admin_*     │
└───────────────────────────┬─────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────┐
│                 Provider Layer (State)                   │
│  AuthProvider, MovieProvider, ConnectivityProvider,      │
│  ThemeProvider                                           │
└───────────────────────────┬─────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────┐
│                  Service Layer (Logic)                   │
│  ApiService, AuthService, ExternalMovieService,          │
│  BookingService, CustomerCatalogService,                 │
│  AdminCatalogService, DeviceService, ProfilePhotoService │
└───────────────────────────┬─────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────┐
│                   Data Layer (Storage)                   │
│  sqflite (LocalDbService), SharedPreferences,            │
│  bundled assets, GitHub external JSON, SSP API             │
└─────────────────────────────────────────────────────────┘
```

### Layer responsibilities

| Layer | Components | Responsibility |
|-------|------------|----------------|
| **UI Layer** | Screens (`lib/screens/`), reusable widgets (`lib/widgets/`) | Renders Material UI, captures user input, navigates between flows, displays catalogue and booking data. Does not perform direct HTTP or SQL operations. |
| **Provider Layer** | `AuthProvider`, `MovieProvider`, `ConnectivityProvider`, `ThemeProvider` | Holds application state, exposes read-only getters, calls services, and notifies listeners when data changes so UI rebuilds efficiently. |
| **Service Layer** | `ApiService`, `ExternalMovieService`, `BookingService`, catalog merge services, etc. | Encapsulates business rules: authentication order (API then local), catalogue merge priority, booking persistence, device capability access, and profile storage. |
| **Data Layer** | sqflite tables, SharedPreferences keys, asset JSON, remote API/JSON | Stores and retrieves persistent and remote data. External JSON is written to sqflite on successful fetch; bookings and favourites are read by customer screens from the same local sources. |

### Data flow example (movie catalogue)

1. `MovieProvider.load()` invokes `ExternalMovieService.fetchMovies()`.
2. On network success, JSON is parsed, cached in sqflite, synced to SharedPreferences movie records, and returned with source `network`.
3. `CustomerCatalogService.mergeCustomerMovies()` merges live external rows with admin-local overrides.
4. `HomeScreen` and related customer screens consume `MovieProvider.movies` for display.

### Data flow example (booking)

1. User completes seat selection on `BookingScreen` and proceeds to `PaymentScreen`.
2. On successful simulated payment, `LocalDbService.insertBooking()` persists the booking in sqflite.
3. `BookingService.saveBooking()` also mirrors booking data in SharedPreferences for legacy/admin compatibility.
4. `MyBookingsScreen` loads bookings via `LocalDbService.getBookingsByUser()`; `ProfileScreen` refreshes the same count when the Profile tab becomes active.

---

## 7. Application Features

### 7.1 Authentication

- **Customer registration** (`SignupScreen`) — collects name, email, and password with validation; attempts SSP API registration first, then local registry fallback.
- **Customer login** (`LoginScreen`) — validates credentials; attempts Laravel Sanctum login via `ApiService.login()`; on API failure, falls back to `AuthService.authenticateUser()`.
- **SSP authentication** — Sanctum tokens stored under `sanctum_token` in SharedPreferences; session hydrated on app start via `AuthProvider.hydrate()`.
- **Admin / customer roles** — determined from API user role or local registry; admin users (`admin@moviebuff.com` or role `admin`) are routed to `AdminDashboardScreen`; customers to `HomeScreen`.
- **Logout** — clears local session and API token; returns user to login.

### 7.2 Movie Catalogue

- **External JSON** — master list fetched from GitHub raw URL configured in `AppConfig.externalMoviesUrl`.
- **Live catalogue** — Home screen “Live Catalogue” horizontal list with source badge (Live / Cached / Offline).
- **Offline fallback** — order: network → sqflite `movie_cache` table → bundled `assets/data/external_movies.json`.
- **Cache system** — successful network responses stored via `LocalDbService.writeMovieCache()`; force refresh bypasses HTTP cache with timestamp query parameter.
- **Master/detail structure** — Home lists movies; `MovieDetailsScreen` shows full metadata, trailer link, and booking entry; `TheatresScreen` and `TheatreDetailsScreen` expose venue-specific showtimes derived from merged catalogue data.
- **Image sync** — `MovieCatalogSyncService` upserts poster URLs from live JSON into local movie records and clears Flutter image cache after refresh.

### 7.3 Booking System

- **Movie booking** — user selects showtime from theatre/movie details, opens `BookingScreen` seat grid (rows A–H, 8 columns), toggles available seats, views live booking summary.
- **Payment simulation** — `PaymentScreen` collects card-style fields with validation; no real payment gateway; confirms booking on successful form submission.
- **Booking persistence** — primary customer store: sqflite `bookings` table via `LocalDbService.insertBooking()`; booking list in `MyBookingsScreen` reads from `LocalDbService.getBookingsByUser()`.
- **Cancellation** — active bookings can request cancellation on `CancelBookingScreen` with 50% refund policy messaging; status updated in local storage.

### 7.4 Admin Features

- **Admin dashboard** — overview statistics, quick actions, and navigation to management screens.
- **CRUD movies** (`AdminMoviesScreen`) — add, edit, suppress, and refresh catalogue; merges with live external JSON via `AdminCatalogService.mergeMoviesForAdmin()`.
- **CRUD theatres** (`AdminTheatresScreen`) — manage theatre records merged from catalogue and local admin data.
- **CRUD showtimes** (`AdminShowtimesScreen`) — manage showtime templates linked to movies and theatres.
- **Admin bookings & cancellations** — view booking records and cancellation requests from local booking service data.
- **Synchronization with customer side** — admin edits flagged `_adminLocal` in SharedPreferences; `CustomerCatalogService` and `AdminCatalogService` merge admin-local rows over external catalogue; `MovieProvider.refreshAfterAdminEdit()` re-merges after admin changes.

### 7.5 Mobile Device Capabilities

- **Connectivity status** — `ConnectivityProvider` and `ConnectivityBanner` show Online (Wi-Fi/mobile) or Offline; Device screen explains cached catalogue behaviour when offline.
- **Geolocation** — Device screen “Find nearest cinema” uses `DeviceService.acquireRealLocation()` and maps coordinates to nearest Sri Lankan cinema reference points.
- **Battery status** — Device screen displays percentage and charging state via `battery_plus`.
- **Camera / gallery profile image** — Profile screen avatar camera icon opens bottom sheet (Take Photo / Choose from Gallery / Remove Photo); stored per user email via `ProfilePhotoService` (not on Device screen).
- **Dark / light mode** — `ThemeProvider` supports System, Light, and Dark modes; toggled from Profile screen; persisted in SharedPreferences.

---

## 9. Test Case Documentation

The following test cases reflect **implemented MovieBuff functionality** only. All cases were executed successfully during development and validation.

| Test Case ID | Category | Description | Prerequisites | Test Procedure | Input Data | Expected Results | Pass/Fail |
|--------------|----------|-------------|---------------|----------------|------------|------------------|-----------|
| TC-01 | Authentication | Verify customer registration | User is on Signup screen; network optional | 1. Open app Signup tab 2. Enter valid name, email, password 3. Tap Register | Name: Test User; Email: test@example.com; Password: valid password | Registration succeeds; user session created; navigates to Home or shows success and allows login | Pass |
| TC-02 | Authentication | Validate login with correct credentials | Test account exists locally or on SSP API | 1. Open Login screen 2. Enter registered email and password 3. Tap Login | Valid email and password | User logged in; Home screen displayed for customer role | Pass |
| TC-03 | Authentication | Reject login with invalid credentials | User on Login screen | 1. Enter unregistered email or wrong password 2. Tap Login | Invalid credentials | Error message displayed: Invalid email or password; no session created | Pass |
| TC-04 | Authentication | Admin login routing | Admin account exists (e.g. admin role or admin@moviebuff.com) | 1. Login with admin credentials 2. Observe landing screen | Admin email/password | Admin Dashboard displayed instead of customer Home | Pass |
| TC-05 | External JSON | Load live movie catalogue from GitHub | Device online; external URL configured | 1. Launch app as customer 2. Open Home tab 3. Wait for catalogue load | None | Live Catalogue section populated; badge shows live external JSON source | Pass |
| TC-06 | External JSON | Force refresh catalogue | Device online | 1. On Home Live Catalogue tap refresh icon 2. Wait for completion | None | SnackBar shows movie count and source label; updated data displayed | Pass |
| TC-07 | Offline Support | Offline fallback to sqflite cache | Previous successful JSON fetch cached | 1. Load catalogue while online 2. Disable network 3. Restart app or refresh | None | Catalogue loads from cache; banner indicates offline/cached state | Pass |
| TC-08 | Offline Support | Bundled asset fallback | No network and empty cache (first install offline) | 1. Install/run app without network 2. Open Home | None | Movies load from bundled asset JSON; offline badge shown | Pass |
| TC-09 | Movie Listing | Display movies on Home screen | Catalogue loaded | 1. Open Home tab 2. Scroll hero carousel and Live Catalogue list | None | Movie titles, genres, and posters displayed without layout overflow | Pass |
| TC-10 | Movie Details | View movie detail page | Movies visible on Home or Theatres | 1. Tap a movie card 2. Review detail screen | Movie selection | MovieDetailsScreen shows title, description, rating, trailer action, and book option | Pass |
| TC-11 | Theatre Listing | Display theatres for customer | Catalogue contains theatre/showtime data | 1. Open Theatres tab 2. Browse list | None | Theatre names and locations displayed from merged catalogue | Pass |
| TC-12 | Showtime Management | Display showtimes for selected movie/theatre | Showtimes initialized in ShowtimeService | 1. Open movie or theatre details 2. View available showtimes | Movie/theatre selection | Showtime chips or list displayed for booking selection | Pass |
| TC-13 | Seat Selection | Select available seats | User navigated to BookingScreen with valid showtime | 1. Tap available seats on grid 2. Observe summary | Seat IDs e.g. A2, A3 | Selected seats highlighted; booking summary shows seat list and price | Pass |
| TC-14 | Seat Validation | Prevent booking without seat selection | User on BookingScreen; no seats selected | 1. Do not select any seat 2. Attempt to find Proceed to Payment | None | Proceed to Payment control not shown until at least one seat selected | Pass |
| TC-15 | Booking Flow | Complete booking from seat to payment | User logged in; seats selected | 1. Select seats 2. Tap Proceed to Payment 3. Complete payment form 4. Confirm | Valid card-style fields | Booking confirmed message; navigation to My Bookings | Pass |
| TC-16 | Payment Simulation | Validate payment form fields | User on PaymentScreen | 1. Leave card fields empty 2. Tap Pay 3. Enter invalid then valid data | Empty/invalid/valid card data | Validation errors on empty/invalid; success path on valid input | Pass |
| TC-17 | Booking Persistence | Persist booking in sqflite | User completed TC-15 | 1. Open My Bookings tab 2. View Active tab | None | New booking visible with movie, theatre, date, time, seats, amount | Pass |
| TC-18 | Booking Persistence | Profile booking count matches My Bookings | Booking saved in TC-15 | 1. Open Profile tab 2. Check Local bookings activity line | None | Count matches number of sqflite bookings for logged-in user without app restart | Pass |
| TC-19 | Favourites | Save movie to favourites | User on Home Live Catalogue | 1. Tap heart icon on a movie 2. Open Device tab favourites section | Movie title | SnackBar confirms save; favourite appears in Device list | Pass |
| TC-20 | Favourites | Favourites stored in sqflite | Favourite added in TC-19 | 1. Restart app 2. Open Device tab | None | Previously saved favourite still listed | Pass |
| TC-21 | Admin CRUD | Admin add/edit movie | Admin logged in | 1. Open Manage Movies 2. Add or edit movie 3. Save | Movie form data | Movie appears in admin list; customer catalogue reflects merge after refresh | Pass |
| TC-22 | Admin CRUD | Admin manage theatres | Admin logged in | 1. Open Manage Theatres 2. Add or edit theatre | Theatre form data | Theatre saved locally; visible in admin and customer merge | Pass |
| TC-23 | Admin CRUD | Admin manage showtimes | Admin logged in | 1. Open Manage Showtimes 2. Create or edit showtime | Showtime data | Showtime associated with movie/theatre; available on customer flow after merge | Pass |
| TC-24 | Profile Image | Upload profile photo from gallery | Customer logged in; gallery permission granted | 1. Open Profile tab 2. Tap avatar camera icon 3. Choose from Gallery 4. Select image | Image file | Avatar updates immediately; photo persisted for current user | Pass |
| TC-25 | Profile Image | Per-user photo isolation | Two user accounts available | 1. Login as User A; set photo 2. Logout 3. Login as User B | Two accounts | User B does not see User A photo; default avatar shown until B sets photo | Pass |
| TC-26 | Connectivity | Detect online state | Device connected to Wi-Fi or mobile data | 1. Open app 2. Observe connectivity banner and Device screen | None | Banner shows Online · Wi-Fi or Mobile; Device network card shows Online | Pass |
| TC-27 | Connectivity | Detect offline state | Device airplane mode or no network | 1. Disable connectivity 2. Open app | None | Banner shows Offline; Device screen indicates offline/cached behaviour | Pass |
| TC-28 | Battery Display | Show battery percentage | App running on physical device or emulator with battery API | 1. Open Device tab 2. View Battery section | None | Battery percentage and charging state displayed | Pass |
| TC-29 | Geolocation | Find nearest cinema | Location permission granted | 1. Open Device tab 2. Tap Find nearest cinema | GPS coordinates | Nearest cinema name and distance (km) displayed | Pass |
| TC-30 | Theme | Toggle light and dark mode | User on Profile screen | 1. Tap theme icon in Profile app bar 2. Cycle System → Light → Dark | None | UI theme changes accordingly; preference persists after restart | Pass |
| TC-31 | Cache Persistence | External JSON cached after live fetch | Device was online | 1. Fetch live JSON 2. Inspect subsequent offline load | None | Cached movies match last successful fetch; sqflite cache timestamp updated | Pass |
| TC-32 | SSP API Connection | Test SSP API from Device screen | Laravel API running; AppConfig URL reachable | 1. Open Device tab 2. Tap Test SSP API Connection | API base URL from AppConfig | Result shows reachable or unreachable with response detail SnackBar | Pass |
| TC-33 | Cancellation | Request booking cancellation | Active booking exists | 1. My Bookings → Active 2. Cancel Booking 3. Confirm cancellation flow | Cancellation reason | Booking status updated to cancellation requested/cancelled; visible in Cancelled tab | Pass |
| TC-34 | Navigation | Bottom navigation tab switching | Customer logged in on Home | 1. Tap each tab: Home, Theatres, Bookings, Device, Profile | None | Correct screen displayed; tab state preserved without unnecessary reload spinners | Pass |

---

## 10. Challenges Faced During Development

### Admin and customer catalogue synchronization

Maintaining a single logical movie catalogue for both admin CRUD and customer browsing required careful merge rules. Admin-local records (stored in SharedPreferences with `_adminLocal`) had to overlay live external JSON without blocking updated poster URLs. Implementing `CustomerCatalogService`, `AdminCatalogService`, and `MovieCatalogSyncService` resolved conflicts by prioritizing live JSON for catalogue rows while preserving intentional admin overrides.

### External JSON caching and image updates

GitHub-hosted JSON could update poster URLs while the app continued displaying stale images from sqflite cache, SharedPreferences seeds, or Flutter’s image cache. The solution combined force-refresh with cache-busting query parameters, upsert logic on successful fetch, and targeted image cache eviction after live refresh.

### Offline support

The application must remain usable without network access for demonstrations and marking criteria. A three-tier fallback (network → sqflite cache → bundled asset) was implemented in `ExternalMovieService`, with connectivity indicators explaining reduced functionality when offline.

### State management and tab lifecycle

Bottom navigation uses a keep-alive `PageView`, which improved performance but caused Profile activity counts and booking statistics to appear stale until tab reactivation. Refresh triggers on Profile tab visibility, auth changes, and app resume were added without altering booking save logic.

### Performance and UI smoothness

Premium UI effects (blur, shadows, large images) initially caused scroll jank on mid-range devices. Optimizations included `RepaintBoundary`, image decode sizing, `Selector`-based provider listening, keep-alive tabs, and reduced heavy effects on list items—validated in release mode rather than debug alone.

### Theme adaptation and branding

The MovieBuff logo asset uses light lettering, requiring theme-specific rendering (tint on light surfaces) without adding background boxes that conflicted with the cinematic card design. Material 3 light/dark themes were extended with custom `AppColors` and persistent theme mode cycling.

### SSP API connectivity in development

Laravel Sanctum endpoints behave differently across emulator loopback (`10.0.2.2`), USB `adb reverse`, and LAN IP configurations. Centralized `AppConfig.apiBaseUrl` and the Device screen “Test SSP API Connection” button simplified diagnosis without changing authentication business rules.

---

## 13. References

1. Flutter Documentation — https://docs.flutter.dev/
2. Dart Language Documentation — https://dart.dev/guides
3. Provider package — https://pub.dev/packages/provider
4. sqflite package — https://pub.dev/packages/sqflite
5. connectivity_plus — https://pub.dev/packages/connectivity_plus
6. geolocator — https://pub.dev/packages/geolocator
7. battery_plus — https://pub.dev/packages/battery_plus
8. image_picker — https://pub.dev/packages/image_picker
9. Laravel Documentation — https://laravel.com/docs
10. Laravel Sanctum — https://laravel.com/docs/sanctum
11. Material Design 3 — https://m3.material.io/
12. HTTP package (Dart) — https://pub.dev/packages/http
13. SharedPreferences — https://pub.dev/packages/shared_preferences

---

*End of MAD II Report Support Document — MovieBuff Flutter Application*
