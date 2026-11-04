import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../providers/storage_status_service.dart';

/// Keeps detection alive even when no drive icon is currently present.
class StorageStatusWatch extends StatefulWidget {
  final bool visible;
  final Widget child;
  const StorageStatusWatch({
    super.key,
    required this.visible,
    required this.child,
  });
  @override
  State<StorageStatusWatch> createState() => _StorageStatusWatchState();
}

class _StorageStatusWatchState extends State<StorageStatusWatch> {
  StorageStatusService? _service;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final service = context.read<StorageStatusService?>();
    if (service != _service) {
      _service?.setVisible(this, false);
      _service = service;
    }
    _service?.setVisible(this, widget.visible);
  }

  @override
  void didUpdateWidget(StorageStatusWatch oldWidget) {
    super.didUpdateWidget(oldWidget);
    _service?.setVisible(this, widget.visible);
  }

  @override
  void dispose() {
    _service?.setVisible(this, false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
