import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/net_ui_state.dart';
import '../controllers/net_ui_controller.dart';
import '../widgets/net_banner.dart';

class ConnectivityDemoPage extends ConsumerWidget {
  const ConnectivityDemoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(netUiControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Connectivity (Clean + Riverpod)"),
      ),
      body: Stack(
        children: [
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

          Align(
            alignment: Alignment.topCenter,
            child: SafeArea(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: state == NetUiState.hidden
                    ? const SizedBox.shrink()
                    : NetBanner(state: state),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
