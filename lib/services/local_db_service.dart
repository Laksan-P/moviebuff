import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// sqflite-backed local storage.
///
/// Laravel remains authoritative for API bookings, auth, admin CRUD, payments,
/// and cancellation workflows. SQLite bookings exist for:
///   • External JSON movies (offline booking demonstration)
///   • MAD II local persistence requirements
///
/// SQLite booking CRUD (report support):
///   • CREATE — [insertBooking]
///   • READ   — [getBookingsByUser], [getBookingById], [countAllBookings]
///   • UPDATE — [updateBookingStatus] (e.g. Confirmed → Cancelled)
///   • DELETE — [deleteBooking]
class LocalDbService {
  static const _dbName = 'moviebuff.db';
  static const _dbVersion = 3;

  static const _favTable = 'favorites';
  static const _cacheTable = 'movie_cache';
  static const _bookingsTable = 'bookings';

  static Database? _db;

  static Future<void> _createFavoritesAndCache(Database db) async {
    await db.execute('''
      CREATE TABLE $_favTable (
        title       TEXT PRIMARY KEY,
        image       TEXT,
        genre       TEXT,
        added_at    INTEGER NOT NULL
      );
    ''');
    await db.execute('''
      CREATE TABLE $_cacheTable (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        source      TEXT NOT NULL,
        payload     TEXT NOT NULL,
        fetched_at  INTEGER NOT NULL
      );
    ''');
  }

  static Future<void> _createBookingsTable(Database db) async {
    await db.execute('''
      CREATE TABLE $_bookingsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id TEXT,
        user_email TEXT NOT NULL,
        movie_id TEXT,
        movie_title TEXT NOT NULL,
        theatre TEXT NOT NULL,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        seats TEXT NOT NULL,
        ticket_count INTEGER NOT NULL DEFAULT 1,
        amount REAL NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0,
        booking_source TEXT NOT NULL DEFAULT 'sqlite'
      );
    ''');
  }

  static Future<void> _upgradeBookingsToV3(Database db) async {
    final columns = await db.rawQuery('PRAGMA table_info($_bookingsTable)');
    final names = columns.map((c) => c['name']?.toString()).toSet();
    if (!names.contains('movie_id')) {
      await db.execute(
        'ALTER TABLE $_bookingsTable ADD COLUMN movie_id TEXT',
      );
    }
    if (!names.contains('ticket_count')) {
      await db.execute(
        'ALTER TABLE $_bookingsTable ADD COLUMN ticket_count INTEGER NOT NULL DEFAULT 1',
      );
    }
    if (!names.contains('booking_source')) {
      await db.execute(
        "ALTER TABLE $_bookingsTable ADD COLUMN booking_source TEXT NOT NULL DEFAULT 'sqlite'",
      );
    }
  }

  static Future<Database> _database() async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, _dbName);
    debugPrint('🗄️ SQFLITE - Opening database at: $path');

    _db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, _) async {
        debugPrint('🗄️ SQFLITE - onCreate v$_dbVersion');
        await _createFavoritesAndCache(db);
        await _createBookingsTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        debugPrint('🗄️ SQFLITE - onUpgrade $oldVersion → $newVersion');
        if (oldVersion < 2) {
          await _createBookingsTable(db);
        }
        if (oldVersion < 3) {
          await _upgradeBookingsToV3(db);
        }
      },
    );
    return _db!;
  }

  // ---------- Favorites ----------

  static Future<void> addFavorite(Map<String, dynamic> movie) async {
    final db = await _database();
    await db.insert(_favTable, {
      'title': movie['title'],
      'image': movie['image'] ?? '',
      'genre': movie['genre'] ?? '',
      'added_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    debugPrint('⭐ SQFLITE - Added favorite: ${movie['title']}');
  }

  static Future<void> removeFavorite(String title) async {
    final db = await _database();
    final n = await db.delete(
      _favTable,
      where: 'title = ?',
      whereArgs: [title],
    );
    debugPrint('⭐ SQFLITE - Removed favorite ($n row): $title');
  }

  static Future<bool> isFavorite(String title) async {
    final db = await _database();
    final rows = await db.query(
      _favTable,
      where: 'title = ?',
      whereArgs: [title],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  static Future<List<Map<String, dynamic>>> getFavorites() async {
    final db = await _database();
    final rows = await db.query(_favTable, orderBy: 'added_at DESC');
    debugPrint('⭐ SQFLITE - Loaded ${rows.length} favorites');
    return rows;
  }

  static Future<void> updateFavoriteImage(String title, String imageUrl) async {
    if (title.trim().isEmpty || imageUrl.trim().isEmpty) return;
    final db = await _database();
    final n = await db.update(
      _favTable,
      {'image': imageUrl},
      where: 'title = ?',
      whereArgs: [title],
    );
    if (n > 0) {
      debugPrint('⭐ SQFLITE - Updated favorite poster for: $title');
    }
  }

  // ---------- Movie cache ----------

  static Future<void> writeMovieCache(
    String source,
    List<dynamic> payload,
  ) async {
    final db = await _database();
    await db.delete(_cacheTable, where: 'source = ?', whereArgs: [source]);
    await db.insert(_cacheTable, {
      'source': source,
      'payload': jsonEncode(payload),
      'fetched_at': DateTime.now().millisecondsSinceEpoch,
    });
    debugPrint(
      '🗄️ SQFLITE - Cached ${payload.length} entries for source: $source',
    );
  }

  static Future<List<Map<String, dynamic>>?> readMovieCache(
    String source,
  ) async {
    final db = await _database();
    final rows = await db.query(
      _cacheTable,
      where: 'source = ?',
      whereArgs: [source],
      limit: 1,
    );
    if (rows.isEmpty) return null;

    final raw = rows.first['payload'] as String;
    final decoded = jsonDecode(raw) as List<dynamic>;
    debugPrint(
      '🗄️ SQFLITE - Loaded ${decoded.length} cached entries for $source',
    );
    return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<DateTime?> cacheTimestamp(String source) async {
    final db = await _database();
    final rows = await db.query(
      _cacheTable,
      columns: ['fetched_at'],
      where: 'source = ?',
      whereArgs: [source],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DateTime.fromMillisecondsSinceEpoch(rows.first['fetched_at'] as int);
  }

  /// JSON object cache for arbitrary keyed payloads.
  static Future<void> writeObjectCache(
    String source,
    Map<String, dynamic> payload,
  ) async {
    final db = await _database();
    await db.delete(_cacheTable, where: 'source = ?', whereArgs: [source]);
    await db.insert(_cacheTable, {
      'source': source,
      'payload': jsonEncode(payload),
      'fetched_at': DateTime.now().millisecondsSinceEpoch,
    });
    debugPrint('🗄️ SQFLITE - Cached object for source: $source');
  }

  static Future<Map<String, dynamic>?> readObjectCache(String source) async {
    final db = await _database();
    final rows = await db.query(
      _cacheTable,
      where: 'source = ?',
      whereArgs: [source],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final raw = rows.first['payload'] as String;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    debugPrint('🗄️ SQFLITE - Loaded object cache for $source');
    return Map<String, dynamic>.from(decoded);
  }

  // ---------- Bookings ----------

  static double _parseAmount(dynamic raw) {
    final s = raw?.toString() ?? '0';
    return double.tryParse(s.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
  }

  static String _formatBookingDateFromIso(String iso) {
    try {
      final d = DateTime.parse(iso);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[d.month - 1]} ${d.day.toString().padLeft(2, '0')}, ${d.year}';
    } catch (_) {
      return iso;
    }
  }

  static String _ticketsFromSeats(String? seats) {
    if (seats == null || seats.trim().isEmpty) return '1';
    return seats.split(',').length.toString();
  }

  static String _normalizeLocalStatus(String? raw) {
    final s = raw?.toLowerCase().trim() ?? '';
    if (s == 'cancelled') return 'offline_cancelled';
    return 'offline_confirmed';
  }

  /// Maps a DB row to the shape expected by My Bookings / cancel UI.
  static Map<String, dynamic> _bookingRowToUiMap(Map<String, Object?> row) {
    final created = row['created_at'] as String? ?? '';
    final synced = (row['synced'] as int? ?? 0) == 1;
    final statusLabel = row['status']?.toString() ?? 'Confirmed';
    final apiStatus = _normalizeLocalStatus(statusLabel);
    final tickets = row['ticket_count']?.toString() ??
        _ticketsFromSeats(row['seats'] as String?);
    return {
      'id': row['id'].toString(),
      'server_id': row['server_id'],
      'movie_id': row['movie_id']?.toString(),
      'movieId': row['movie_id']?.toString(),
      'movie': row['movie_title']?.toString() ?? '',
      'theatre': row['theatre']?.toString() ?? '',
      'date': row['date']?.toString() ?? '',
      'time': row['time']?.toString() ?? '',
      'showtime': '${row['date']} ${row['time']}',
      'seats': row['seats']?.toString() ?? '',
      'amount': row['amount']?.toString() ?? '0',
      'total_price': row['amount']?.toString() ?? '0',
      'tickets': tickets,
      'ticket_count': tickets,
      'status': statusLabel,
      '_api_status': apiStatus,
      'bookingDate': _formatBookingDateFromIso(created),
      'booking_date': created,
      'synced': synced,
      'bookingSource': 'offline',
      'sourceBadge': 'Offline Booking',
      'email': row['user_email']?.toString() ?? '',
      'format': '2D',
      'language': 'English',
      'name': '',
      'is_local_booking': true,
    };
  }

  /// CREATE — inserts an offline/external JSON booking row.
  static Future<int> insertBooking(Map<String, dynamic> booking) async {
    try {
      final db = await _database();
      final createdAt =
          booking['created_at']?.toString() ?? DateTime.now().toIso8601String();
      final seats = booking['seats']?.toString() ?? '';
      final ticketCount = int.tryParse(booking['tickets']?.toString() ?? '') ??
          int.tryParse(booking['ticket_count']?.toString() ?? '') ??
          seats.split(',').where((s) => s.trim().isNotEmpty).length;
      final rowId = await db.insert(_bookingsTable, {
        'server_id': booking['server_id']?.toString(),
        'user_email': booking['email']?.toString() ?? '',
        'movie_id': booking['movie_id']?.toString() ??
            booking['movieId']?.toString(),
        'movie_title': booking['movie']?.toString() ?? '',
        'theatre': booking['theatre']?.toString() ?? '',
        'date': booking['date']?.toString() ?? '',
        'time': booking['time']?.toString() ?? '',
        'seats': seats,
        'ticket_count': ticketCount < 1 ? 1 : ticketCount,
        'amount': _parseAmount(booking['amount'] ?? booking['total_price']),
        'status': booking['status']?.toString() ?? 'Confirmed',
        'created_at': createdAt,
        'synced': 0,
        'booking_source': booking['booking_source']?.toString() ?? 'sqlite',
      });
      debugPrint('✅ SQFLITE CREATE: booking inserted with id $rowId');
      return rowId;
    } catch (e, st) {
      debugPrint('❌ SQFLITE ERROR: insertBooking — $e\n$st');
      rethrow;
    }
  }

  static Future<int> countAllBookings() async {
    try {
      final db = await _database();
      final r = await db.rawQuery('SELECT COUNT(*) AS c FROM $_bookingsTable');
      return Sqflite.firstIntValue(r) ?? 0;
    } catch (e) {
      debugPrint('❌ SQFLITE ERROR: countAllBookings — $e');
      return 0;
    }
  }

  static Future<int> countCachedMovieRows() async {
    try {
      final db = await _database();
      final rows = await db.query(_cacheTable);
      var total = 0;
      for (final row in rows) {
        final raw = row['payload']?.toString() ?? '[]';
        try {
          final decoded = jsonDecode(raw);
          if (decoded is List) total += decoded.length;
        } catch (_) {}
      }
      return total;
    } catch (e) {
      debugPrint('❌ SQFLITE ERROR: countCachedMovieRows — $e');
      return 0;
    }
  }

  /// READ — single booking by local row id.
  static Future<Map<String, dynamic>?> getBookingById(int id) async {
    try {
      final db = await _database();
      final rows = await db.query(
        _bookingsTable,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return _bookingRowToUiMap(rows.first);
    } catch (e, st) {
      debugPrint('❌ SQFLITE ERROR: getBookingById — $e\n$st');
      return null;
    }
  }

  static Future<int> countBookingsForUser(String userEmail) async {
    try {
      final db = await _database();
      final r = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM $_bookingsTable WHERE user_email = ?',
        [userEmail],
      );
      final n = Sqflite.firstIntValue(r) ?? 0;
      debugPrint('🗄️ SQFLITE - countBookingsForUser($userEmail) = $n');
      return n;
    } catch (e, st) {
      debugPrint('❌ SQFLITE ERROR: countBookingsForUser — $e\n$st');
      return 0;
    }
  }

  static Future<List<Map<String, dynamic>>> getBookingsByUser(
    String userEmail,
  ) async {
    try {
      final db = await _database();
      final rows = await db.query(
        _bookingsTable,
        where: 'user_email = ?',
        whereArgs: [userEmail],
        orderBy: 'id DESC',
      );
      debugPrint(
        '✅ SQFLITE READ SUCCESS: loaded ${rows.length} bookings for user '
        '$userEmail',
      );
      return rows.map((r) => _bookingRowToUiMap(r)).toList();
    } catch (e, st) {
      debugPrint('❌ SQFLITE ERROR: getBookingsByUser — $e\n$st');
      rethrow;
    }
  }

  /// UPDATE — local booking status (e.g. Confirmed → Cancelled).
  static Future<void> updateBookingStatus(int id, String status) async {
    try {
      final db = await _database();
      final n = await db.update(
        _bookingsTable,
        {'status': status},
        where: 'id = ?',
        whereArgs: [id],
      );
      if (n > 0) {
        debugPrint(
          '✅ SQFLITE UPDATE SUCCESS: booking status updated (id=$id → $status)',
        );
      } else {
        debugPrint('❌ SQFLITE ERROR: updateBookingStatus — no row for id=$id');
      }
    } catch (e, st) {
      debugPrint('❌ SQFLITE ERROR: updateBookingStatus — $e\n$st');
      rethrow;
    }
  }

  /// DELETE — removes a local SQLite booking row.
  static Future<void> deleteBooking(int id) async {
    try {
      final db = await _database();
      await db.delete(_bookingsTable, where: 'id = ?', whereArgs: [id]);
      debugPrint('🗄️ SQFLITE - deleteBooking completed id=$id');
    } catch (e, st) {
      debugPrint('❌ SQFLITE ERROR: deleteBooking — $e\n$st');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getUnsyncedBookings() async {
    try {
      final db = await _database();
      final rows = await db.query(
        _bookingsTable,
        where: 'synced = ?',
        whereArgs: [0],
      );
      return rows.map((r) => Map<String, dynamic>.from(r)).toList();
    } catch (e, st) {
      debugPrint('❌ SQFLITE ERROR: getUnsyncedBookings — $e\n$st');
      rethrow;
    }
  }

  static Future<void> markBookingSynced(int id, String serverId) async {
    try {
      final db = await _database();
      await db.update(
        _bookingsTable,
        {'server_id': serverId, 'synced': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
      debugPrint(
        '✅ SQFLITE UPDATE SUCCESS: booking $id marked synced (server_id=$serverId)',
      );
    } catch (e, st) {
      debugPrint('❌ SQFLITE ERROR: markBookingSynced — $e\n$st');
      rethrow;
    }
  }
}
