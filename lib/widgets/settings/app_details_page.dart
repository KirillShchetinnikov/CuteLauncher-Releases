import 'package:flutter/material.dart';

import '../../models/app.dart';
import '../application_info_panel.dart';

/// Shared app details inside the settings route.
class AppDetailsPage extends StatelessWidget {
  static const String routeName = 'app_details_page';
  final App application;
  const AppDetailsPage({super.key, required this.application});
  @override
  Widget build(BuildContext context) => ApplicationInfoPanel(
    category: null,
    application: application,
    embedded: true,
  );
}
