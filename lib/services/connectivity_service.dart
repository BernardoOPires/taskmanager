import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  ConnectivityService._();
  static final instance = ConnectivityService._();

  final _connectivity = Connectivity();
  final _controller = StreamController<bool>.broadcast();

  bool _isOnline = true;
  bool _forcedOffline = false;

  Stream<bool> get stream => _controller.stream;

  Future<void> start() async {
    final result = await _connectivity.checkConnectivity();
    _isOnline = result != ConnectivityResult.none;
    _controller.add(_isOnline);

    _connectivity.onConnectivityChanged.listen((result) {
      if (_forcedOffline) return;
      _isOnline = result != ConnectivityResult.none;
      _controller.add(_isOnline);
    });
  }

  Future<bool> check() async {
    return _forcedOffline ? false : _isOnline;
  }

  void toggleManual() {
    _forcedOffline = !_forcedOffline;
    _controller.add(!_forcedOffline && _isOnline);
  }
}
