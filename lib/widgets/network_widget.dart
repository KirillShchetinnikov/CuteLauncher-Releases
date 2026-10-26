import 'top_panel_item.dart';
import 'launcher_dialog.dart';
import 'network_summary_dialog.dart';

import 'package:flauncher/providers/network_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NetworkWidget extends StatefulWidget {
  final ValueChanged<bool>? onMenuChanged;
  const NetworkWidget({super.key, this.onMenuChanged});

  @override
  State<NetworkWidget> createState() => _NetworkWidgetState();
}

class _NetworkWidgetState extends State<NetworkWidget> {
  final _focusNode = FocusNode();
  bool _open = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _openSummary(NetworkService service) async {
    if (_open) return;
    final box = _focusNode.context?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final anchor = box.localToGlobal(Offset.zero) & box.size;
    setState(() => _open = true);
    widget.onMenuChanged?.call(true);
    try {
      await showLauncherDialog<void>(
        context: context,
        highlightRect: anchor,
        highlightRectResolver: () => launcherControlBounds(_focusNode),
        useSafeArea: false,
        styleDialog: false,
        barrierColor: Colors.transparent,
        builder: (_) => NetworkSummaryDialog(service: service, anchor: anchor),
      );
    } finally {
      if (mounted) {
        setState(() => _open = false);
        widget.onMenuChanged?.call(false);
        _focusNode.requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Selector<
      NetworkService,
      (NetworkType, CellularNetworkType, int, bool)
    >(
      selector: (_, ns) => (
        ns.networkType,
        ns.cellularNetworkType,
        ns.wirelessNetworkSignalLevel,
        ns.vpnActive,
      ),
      builder: (context, state, _) {
        final (
          networkType,
          cellularNetworkType,
          wirelessSignalLevel,
          vpnActive,
        ) = state;
        final networkService = context.read<NetworkService>();
        IconData physicalIcon = Icons.link_off;

        switch (networkType) {
          case NetworkType.Cellular:
            switch (cellularNetworkType) {
              case CellularNetworkType.Cdma ||
                  CellularNetworkType.Gsm ||
                  CellularNetworkType.Gprs:
                physicalIcon = Icons.g_mobiledata;

              case CellularNetworkType.Edge:
                physicalIcon = Icons.e_mobiledata;

              case CellularNetworkType.Hspa ||
                  CellularNetworkType.Hsdpa ||
                  CellularNetworkType.Hsupa:
                physicalIcon = Icons.h_mobiledata;

              case CellularNetworkType.Hspap:
                physicalIcon = Icons.h_plus_mobiledata;

              case CellularNetworkType.Umts || CellularNetworkType.TdScdma:
                physicalIcon = Icons.three_g_mobiledata;
                break;

              case CellularNetworkType.Lte:
                physicalIcon = Icons.four_g_mobiledata_outlined;
                break;
              case CellularNetworkType.Nr:
                physicalIcon = Icons.five_g;

              default:
                physicalIcon = Icons.question_mark;
                break;
            }
            break;
          case NetworkType.Wifi:
            if (wirelessSignalLevel == 0) {
              physicalIcon = Icons.signal_wifi_0_bar;
            } else if (wirelessSignalLevel == 1) {
              physicalIcon = Icons.network_wifi_1_bar;
            } else if (wirelessSignalLevel == 2) {
              physicalIcon = Icons.network_wifi_2_bar;
            } else if (wirelessSignalLevel == 3) {
              physicalIcon = Icons.network_wifi_3_bar;
            } else {
              physicalIcon = Icons.signal_wifi_4_bar;
            }
            break;
          case NetworkType.Vpn:
            physicalIcon = Icons.vpn_key;
            break;
          case NetworkType.Wired:
            physicalIcon = Icons.lan;
            break;
          case NetworkType.Unknown:
            physicalIcon = Icons.link_off;

            break;
        }

        Widget physicalWidget = Icon(
          physicalIcon,

          shadows: const [
            Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 8),
          ],
        );

        if (!vpnActive || physicalIcon == Icons.vpn_key) {
          return TopPanelItem(
            focusNode: _focusNode,
            selected: _open,
            onPressed: () => _openSummary(networkService),
            child: physicalWidget,
          );
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          textDirection: TextDirection.ltr,
          children: [
            TopPanelItem(
              focusNode: _focusNode,
              selected: _open,
              onPressed: () => _openSummary(networkService),
              child: physicalWidget,
            ),
            const SizedBox(width: 4),
            TopPanelItem(
              onPressed: () => networkService.openVpnSettings(),
              child: const Icon(
                Icons.vpn_key,
                shadows: [
                  Shadow(
                    color: Colors.black54,
                    offset: Offset(0, 2),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
