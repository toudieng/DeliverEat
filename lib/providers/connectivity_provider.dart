import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/connectivity/connectivity_service.dart';

class ConnectivityProvider extends ChangeNotifier {
  bool isOnline = true;
  StreamSubscription<bool>? _sub;

  Future<void> bootstrap() async {
    isOnline = await ConnectivityService.instance.isOnline;
    notifyListeners();
    _sub = ConnectivityService.instance.onStatusChange.listen((online) {
      if (online != isOnline) {
        isOnline = online;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
