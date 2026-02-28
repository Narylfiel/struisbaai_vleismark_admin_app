import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Exposes current connectivity status to the app.
/// Used for offline banner and cache/sync behaviour. No Supabase ping — device network only.
class ConnectivityService {
  ConnectivityService._() {
    _init();
  }
  static final ConnectivityService _instance = ConnectivityService._();
  factory ConnectivityService() => _instance;

  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _lastValue = true;

  /// Stream of connection status: true = has network, false = offline.
  Stream<bool> get connectionStatus => _controller.stream;

  /// Current value (latest emitted). Default true to avoid showing banner before first check.
  bool get isConnected => _lastValue;

  void _init() {
    Connectivity().checkConnectivity().then(_emitFromResults);
    _subscription = Connectivity().onConnectivityChanged.listen(_emitFromResults);
  }

  void _emitFromResults(List<ConnectivityResult> results) {
    final connected = results.isNotEmpty &&
        results.any((r) => r != ConnectivityResult.none);
    if (connected != _lastValue) {
      _lastValue = connected;
      if (!_controller.isClosed) {
        _controller.add(connected);
      }
    }
  }

  /// Call when app is disposed (e.g. in tests). Normal app run keeps service alive.
  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}
