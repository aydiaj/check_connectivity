import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

void main() => runApp(const MyApp());

/// UI states we want to show.
enum NetUiState { hidden, offline, connecting, connected }

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ConnectivityDemoPage(),
    );
  }
}

class ConnectivityDemoPage extends StatefulWidget {
  const ConnectivityDemoPage({super.key});

  @override
  State<ConnectivityDemoPage> createState() =>
      _ConnectivityDemoPageState();
}

class _ConnectivityDemoPageState extends State<ConnectivityDemoPage> {
  // ---------------------------------------------------------------------------
  // WHY NOT ONLY StreamBuilder?
  // ---------------------------------------------------------------------------
  // We DO use StreamBuilder in the UI (below). But:
  //
  // 1) StreamBuilder listens to ONE stream.
  // 2) Here we have TWO different streams:
  //    - Connectivity().onConnectivityChanged  -> tells us if an interface exists
  //    - InternetConnection().onStatusChange   -> tells us if internet is reachable
  //
  // We want ONE UI state (NetUiState) that depends on BOTH streams + extra rules:
  //    - If no interface => Offline
  //    - If interface exists but no internet => Connecting
  //    - If internet reachable => Connected (show 3 seconds then hidden)
  //
  // If we used StreamBuilder "directly" on both streams, we'd have either:
  //   A) Two StreamBuilders (nested) and combine the values inside build()
  //      -> UI becomes messy + harder to add the 3-second auto-hide
  //   B) A combined stream (using RxDart combineLatest, etc.)
  //      -> still ends up as "one stream for the UI"
  //
  // So we build ONE clean stream: Stream<NetUiState> and let StreamBuilder
  // rebuild only based on that single, final UI-ready state.
  // ---------------------------------------------------------------------------

  /// This controller is our "combined stream" for the UI.
  /// It emits ONE thing the UI cares about: NetUiState.
  ///
  /// broadcast => allows multiple listeners (not required, but safe for demos).
  final StreamController<NetUiState> _stateController =
      StreamController<NetUiState>.broadcast();

  /// Subscriptions to the TWO source streams (so we can cancel in dispose()).
  StreamSubscription<List<ConnectivityResult>>? _connSub;
  StreamSubscription<InternetStatus>? _internetSub;

  /// The current UI state (to avoid emitting the same state repeatedly).
  NetUiState _current = NetUiState.hidden;

  /// Timer used for the rule: show "Connected" for 3 seconds, then hide.
  Timer? _hideTimer;

  /// From connectivity_plus:
  /// true  => there is a network interface (Wi-Fi/Mobile/Ethernet)
  /// false => no interface at all (ConnectivityResult.none)
  bool _hasInterface = false;

  /// From internet_connection_checker_plus:
  /// connected/disconnected = real internet reachability (not just Wi-Fi).
  InternetStatus _internetStatus = InternetStatus.disconnected;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  Future<void> _startListening() async {
    // Initial one-time checks (so UI is correct immediately on startup)
    final initialConn = await Connectivity().checkConnectivity();
    _hasInterface = !initialConn.contains(ConnectivityResult.none);

    final initialInternet =
        await InternetConnection().hasInternetAccess;
    _internetStatus = initialInternet
        ? InternetStatus.connected
        : InternetStatus.disconnected;

    _recomputeAndEmit();

    // Source stream #1: network interface changes
    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      _hasInterface = !results.contains(ConnectivityResult.none);
      _recomputeAndEmit(); // combine + emit a single NetUiState
    });

    // Source stream #2: real internet reachability changes
    _internetSub = InternetConnection().onStatusChange.listen((
      status,
    ) {
      _internetStatus = status;
      _recomputeAndEmit(); // combine + emit a single NetUiState
    });
  }

  /// Combine the latest values from BOTH sources into ONE UI-ready state.
  void _recomputeAndEmit() {
    // Any time state changes, cancel pending "auto-hide connected"
    _hideTimer?.cancel();

    // Decide the next UI state based on BOTH pieces of info
    final NetUiState next;
    if (!_hasInterface) {
      next = NetUiState.offline;
    } else if (_internetStatus == InternetStatus.connected) {
      next = NetUiState.connected;
    } else {
      next = NetUiState.connecting;
    }

    // Emit only if it changed (avoid rebuild spam)
    if (next != _current) {
      _current = next;
      _stateController.add(_current);
    }

    // Extra business rule: if connected, show briefly then hide
    if (_current == NetUiState.connected) {
      _hideTimer = Timer(const Duration(seconds: 3), () {
        // Only hide if still connected
        if (_internetStatus == InternetStatus.connected) {
          _current = NetUiState.hidden;
          _stateController.add(_current);
        }
      });
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _connSub?.cancel();
    _internetSub?.cancel();
    _stateController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Connectivity (Event-driven)"),
      ),
      body: Stack(
        children: [
          // Optional page content
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                "Toggle your internet and observe states:\n"
                "1) Offline (no interface)\n"
                "2) Connecting...\n"
                "3) Connected (shows for 3s then hides)",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),

          // -----------------------------------------------------------------
          // HERE is StreamBuilder:
          // It listens to ONE stream: _stateController.stream (NetUiState).
          // The UI rebuilds ONLY when the combined UI state changes.
          // -----------------------------------------------------------------
          Align(
            alignment: Alignment.topCenter,
            child: SafeArea(
              child: StreamBuilder<NetUiState>(
                stream: _stateController.stream,
                initialData: _current,
                builder: (context, snapshot) {
                  final state = snapshot.data ?? NetUiState.hidden;
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: state == NetUiState.hidden
                        ? const SizedBox.shrink()
                        : _NetBanner(state: state),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NetBanner extends StatelessWidget {
  final NetUiState state;
  const _NetBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    String text;
    IconData icon;
    Color bg;

    switch (state) {
      case NetUiState.offline:
        text = "Offline — Waiting for network…";
        icon = Icons.wifi_off;
        bg = Colors.red.shade600;
        break;
      case NetUiState.connecting:
        text = "Connecting…";
        icon = Icons.sync;
        bg = Colors.orange.shade700;
        break;
      case NetUiState.connected:
        text = "Connected!";
        icon = Icons.check_circle;
        bg = Colors.green.shade700;
        break;
      case NetUiState.hidden:
        text = "";
        icon = Icons.info;
        bg = Colors.transparent;
        break;
    }

    return Container(
      key: ValueKey(state),
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
