import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/apps_service.dart';

/// Package icons also work for installed apps absent from the launcher catalog.
class ApplicationListIcon extends StatefulWidget {
  final String packageName;
  final double size;

  const ApplicationListIcon({
    super.key,
    required this.packageName,
    this.size = 32,
  });

  @override
  State<ApplicationListIcon> createState() => _ApplicationListIconState();
}

class _ApplicationListIconState extends State<ApplicationListIcon> {
  AppsService? _service;
  Future<Uint8List>? _icon;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final service = context.watch<AppsService>();
    if (!identical(service, _service)) {
      _service = service;
      _loadIcon();
    }
  }

  @override
  void didUpdateWidget(ApplicationListIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.packageName != widget.packageName) _loadIcon();
  }

  void _loadIcon() => _icon = _service!.getAppIcon(widget.packageName);

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final fallback = Icon(Icons.android, size: size);
    return SizedBox(
      width: size,
      height: size,
      child: FutureBuilder<Uint8List>(
        future: _icon,
        builder: (_, snapshot) => snapshot.hasData && snapshot.data!.isNotEmpty
            ? Image.memory(
                snapshot.data!,
                width: size,
                height: size,
                cacheWidth: 64,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => fallback,
              )
            : fallback,
      ),
    );
  }
}
