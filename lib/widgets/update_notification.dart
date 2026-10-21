import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/update_service.dart';
import 'action_notice.dart';

/// Delivers update notices above routes once the launcher is visible.
class UpdateNotification extends StatefulWidget {
  final Widget child;
  const UpdateNotification({super.key, required this.child});

  @override
  State<UpdateNotification> createState() => _UpdateNotificationState();
}

class _UpdateNotificationState extends State<UpdateNotification>
    with WidgetsBindingObserver {
  UpdateService? _service;
  bool _scheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final service = context.read<UpdateService?>();
    if (_service != service) {
      _service?.removeListener(_changed);
      _service = service;
      _service?.addListener(_changed);
    }
    _changed();
  }

  void _changed() {
    if (_scheduled || !mounted) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!mounted) return;
      final lifecycle = WidgetsBinding.instance.lifecycleState;
      if (lifecycle != null && lifecycle != AppLifecycleState.resumed) return;
      final version = _service?.takeUpdateNotification();
      if (version != null) {
        showActionNotice(
          context,
          '${AppLocalizations.of(context)!.updateAvailable}: $version',
        );
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _changed();
  }

  @override
  void dispose() {
    _service?.removeListener(_changed);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
