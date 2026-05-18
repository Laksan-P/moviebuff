import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityProvider extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _sub;

  List<ConnectivityResult> _status = const [ConnectivityResult.none];
  List<ConnectivityResult> get status => _status;

  bool get isOnline => _status.any((r) =>
      r == ConnectivityResult.wifi ||
      r == ConnectivityResult.mobile ||
      r == ConnectivityResult.ethernet ||
      r == ConnectivityResult.vpn);

  String get label {
    if (_status.contains(ConnectivityResult.wifi)) return 'Online · Wi-Fi';
    if (_status.contains(ConnectivityResult.mobile)) {
      return 'Online · Mobile data';
    }
    if (_status.contains(ConnectivityResult.ethernet)) return 'Online · Ethernet';
    if (_status.contains(ConnectivityResult.vpn)) return 'Online · VPN';
    return 'Offline';
  }

  Future<void> init() async {
    _status = await _connectivity.checkConnectivity();
    debugPrint('📡 CONNECTIVITY - Initial: $_status');
    notifyListeners();
    _sub = _connectivity.onConnectivityChanged.listen((event) {
      _status = event;
      debugPrint('📡 CONNECTIVITY - Changed: $event ($label)');
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
