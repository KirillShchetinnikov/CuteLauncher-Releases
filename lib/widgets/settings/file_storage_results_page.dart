import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import 'settings_page_layout.dart';

/// Readable from a TV remote even when file access and export are unavailable.
class FileStorageResultsPage extends StatelessWidget {
  final String result;
  const FileStorageResultsPage({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SettingsPageLayout(
      title: Text(l.fileStorageDiagnostics),
      child: Builder(
        builder: (context) {
          final scroll = PrimaryScrollController.of(context);
          return Focus(
            autofocus: true,
            onKeyEvent: (_, event) {
              if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
                return KeyEventResult.ignored;
              }
              final down = event.logicalKey == LogicalKeyboardKey.arrowDown;
              if (!down && event.logicalKey != LogicalKeyboardKey.arrowUp) {
                return KeyEventResult.ignored;
              }
              if (scroll.hasClients) {
                scroll.animateTo(
                  (scroll.offset + (down ? 100 : -100)).clamp(
                    0,
                    scroll.position.maxScrollExtent,
                  ),
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeOut,
                );
              }
              return KeyEventResult.handled;
            },
            child: SingleChildScrollView(
              key: const ValueKey('file_storage_results_scroll'),
              controller: scroll,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l.settingsHelpScroll),
                    const SizedBox(height: 12),
                    Text(
                      result,
                      textDirection: TextDirection.ltr,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
