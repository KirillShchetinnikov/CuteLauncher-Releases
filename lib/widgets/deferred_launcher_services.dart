import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../providers/foreground_work.dart';
import '../providers/backup_automation_service.dart';
import '../providers/update_service.dart';
import '../providers/screensaver_service.dart';

/// Keep non-visual services out of the initial provider dependency cascade.
class DeferredLauncherServices extends StatefulWidget {
  final Widget child;
  const DeferredLauncherServices({super.key, required this.child});
  @override
  State<DeferredLauncherServices> createState() => _DeferredLauncherServicesState();
}

class _DeferredLauncherServicesState extends State<DeferredLauncherServices> {
  ForegroundWork? _work;
  @override
  void initState() {
    super.initState();
    _work = context.read<ForegroundWork?>();
    _work?.schedule(this, () async {
      if (!mounted) return;
      context.read<BackupAutomationService>();
      context.read<UpdateService>();
      context.read<ScreensaverService>().refresh().catchError((Object _) {});
    }, delay: const Duration(seconds: 1)).catchError((Object _) {});
  }
  @override
  void dispose() { _work?.cancel(this); super.dispose(); }
  @override
  Widget build(BuildContext context) => widget.child;
}
