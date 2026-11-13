import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/vpn_service.dart';
import 'launcher_dialog.dart';
import 'top_panel_item.dart';
import 'vpn_menu.dart';

class VpnWidget extends StatefulWidget {
  final FocusNode? focusNode;
  final ValueChanged<bool>? onMenuChanged;
  const VpnWidget({super.key, this.focusNode, this.onMenuChanged});
  @override
  State<VpnWidget> createState() => _VpnWidgetState();
}

class _VpnWidgetState extends State<VpnWidget> {
  final _ownFocus = FocusNode();
  FocusNode get _focus => widget.focusNode ?? _ownFocus;
  bool _open = false;
  Future<void> _show() async {
    if (_open) return;
    final box = _focus.context?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final anchor = box.localToGlobal(Offset.zero) & box.size;
    setState(() => _open = true);
    widget.onMenuChanged?.call(true);
    try {
      await showLauncherDialog<void>(
        context: context,
        highlightRect: anchor,
        highlightRectResolver: () => launcherControlBounds(_focus),
        useSafeArea: false,
        styleDialog: false,
        barrierColor: Colors.transparent,
        builder: (_) => VpnMenu(anchor: anchor),
      );
    } finally {
      if (mounted) {
        setState(() => _open = false);
        widget.onMenuChanged?.call(false);
        if (_focus.context != null) _focus.requestFocus();
      }
    }
  }

  @override
  void dispose() {
    _ownFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vpn = context.watch<VpnService?>();
    if (vpn == null || (!vpn.indicatorVisible && !_open)) {
      return const SizedBox.shrink();
    }
    final l = AppLocalizations.of(context)!;
    final status = vpn.statusUnknown
        ? l.vpnUnknown
        : vpn.active
        ? l.vpnConnected
        : l.vpnDisconnected;
    return Semantics(
      label: '${l.vpnTitle}: $status',
      button: true,
      child: TopPanelItem(
        focusNode: _focus,
        selected: _open,
        onPressed: _show,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              vpn.statusUnknown
                  ? Icons.vpn_key_outlined
                  : vpn.active ? Icons.vpn_key : Icons.vpn_key_off_outlined,
              color: vpn.color && vpn.active && !vpn.failed
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            if (vpn.showName && vpn.target.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(vpn.name(vpn.target)),
            ],
          ],
        ),
      ),
    );
  }
}
