import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final _controller = StreamController<bool>.broadcast();
  Stream<bool> get onStatusChange => _controller.stream;

  bool _last = true;

  Future<void> startMonitoring() async {
    _last = await check();
    _controller.add(_last);

    Connectivity().onConnectivityChanged.listen((_) => _checkNow());

    Timer.periodic(const Duration(seconds: 1), (_) => _checkNow());
  }

  Future<void> _checkNow() async {
    final online = await check();
    if (online != _last) {
      _last = online;
      _controller.add(online);
    }
  }

  Future<bool> check() async {
    final result = await Connectivity().checkConnectivity();
    return result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile;
  }
}
