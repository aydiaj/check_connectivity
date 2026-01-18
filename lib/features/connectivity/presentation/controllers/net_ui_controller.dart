import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

import '../../../../core/network/connectivity_service.dart';
import '../../domain/net_ui_state.dart';

final connectivityServiceProvider = Provider<ConnectivityService>((
  ref,
) {
  return ConnectivityService();
});

final netUiControllerProvider =
    NotifierProvider<NetUiController, NetUiState>(
      NetUiController.new,
    );

class NetUiController extends Notifier<NetUiState> {
  StreamSubscription<bool>? _ifaceSub;
  StreamSubscription<InternetStatus>? _netSub;
  Timer? _hideTimer;

  bool _hasInterface = false;
  InternetStatus _internetStatus = InternetStatus.disconnected;

  @override
  NetUiState build() {
    state = NetUiState.hidden;

    _init();
    ref.onDispose(_disposeInternal);

    return state;
  }

  Future<void> _init() async {
    final service = ref.read(connectivityServiceProvider);

    // 1) Initial snapshot (Futures)
    _hasInterface = await service.hasInterfaceNow();
    final hasInternet = await service.hasInternetNow();
    _internetStatus = hasInternet
        ? InternetStatus.connected
        : InternetStatus.disconnected;

    _recompute();

    // 2) Event-driven updates (Streams)
    _ifaceSub = service.interfaceChanges().listen((hasIface) {
      _hasInterface = hasIface;
      _recompute();
    });

    _netSub = service.internetStatusChanges().listen((status) {
      _internetStatus = status;
      _recompute();
    });
  }

  void _recompute() {
    _hideTimer?.cancel();

    final next = !_hasInterface
        ? NetUiState.offline
        : (_internetStatus == InternetStatus.connected
              ? NetUiState.connected
              : NetUiState.connecting);

    if (next != state) state = next;

    if (state == NetUiState.connected) {
      _hideTimer = Timer(const Duration(seconds: 3), () {
        if (_internetStatus == InternetStatus.connected) {
          state = NetUiState.hidden;
        }
      });
    }
  }

  void _disposeInternal() {
    _hideTimer?.cancel();
    _ifaceSub?.cancel();
    _netSub?.cancel();
  }
}
