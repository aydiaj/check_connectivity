import 'package:flutter/material.dart';

import '../../domain/net_ui_state.dart';

class NetBanner extends StatelessWidget {
  final NetUiState state;
  const NetBanner({super.key, required this.state});

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
