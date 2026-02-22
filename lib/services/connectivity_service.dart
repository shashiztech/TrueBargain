import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Connectivity wrapper — online/offline status with change events
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isConnected = true;
  bool _isOnWifi = false;

  final _controller = StreamController<bool>.broadcast();

  bool get isConnected => _isConnected;
  bool get isOnWifi => _isOnWifi;
  Stream<bool> get onConnectivityChanged => _controller.stream;

  ConnectivityService() {
    _init();
  }

  Future<void> _init() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateStatus(results);
    } catch (_) {
      _isConnected = true; // Safe fallback
    }

    _subscription = _connectivity.onConnectivityChanged.listen(
      (results) => _updateStatus(results),
    );
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final wasConnected = _isConnected;
    _isConnected = results.any((r) => r != ConnectivityResult.none);
    _isOnWifi = results.contains(ConnectivityResult.wifi);

    if (wasConnected != _isConnected) {
      _controller.add(_isConnected);
    }
  }

  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}
