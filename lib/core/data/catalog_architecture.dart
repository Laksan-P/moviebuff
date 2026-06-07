/// Data-source architecture for MovieBuff (MAD II assignment).
///
/// ```text
/// ┌─────────────────────────────────────────────────────────────────┐
/// │                    CORE BUSINESS DATA (CRUD)                    │
/// │  Movies · Theatres · Showtimes · Bookings · Auth · Admin        │
/// └───────────────────────────────┬─────────────────────────────────┘
///                                 │
///                    Primary: Laravel SSP API (Sanctum)
///                                 │
///                    On success → sqflite api_* cache
///                                 │
///              Offline / API failure fallback chain:
///                    sqflite cache → bundled offline_catalog.json
///
/// ┌─────────────────────────────────────────────────────────────────┐
/// │              EXTERNAL JSON — external_movies.json (read-only)   │
/// │  Posters · trailers · descriptions · theatre · showtimes · price│
/// └───────────────────────────────┬─────────────────────────────────┘
///                                 │
///                    Network URL → sqflite external_movies cache
///                                 │
///              Fallback: bundled assets/data/external_movies.json
///                                 │
///              Merged into customer movie list (external titles first)
///
/// ┌─────────────────────────────────────────────────────────────────┐
/// │                    LOCAL PERSISTENCE                            │
/// │  sqflite: favorites, API cache, external JSON cache             │
/// │  SharedPreferences: Sanctum token, auth session, theme, profile │
/// └─────────────────────────────────────────────────────────────────┘
/// ```
///
/// CRUD entities are never written from external JSON. Admin screens always
/// call [ApiService] so the Laravel database remains the source of truth.
library;

/// Where core catalogue rows (movies/theatres/showtimes) were loaded from.
enum CatalogueDataSource {
  laravelApi,
  sqfliteCache,
  localJsonAsset,
  empty,
}
