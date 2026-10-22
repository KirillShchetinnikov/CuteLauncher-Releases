import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/models/tv_input.dart';
import 'package:flauncher/widgets/tv_input_connection_indicator.dart';

void main() {
  testWidgets(
    'all states have distinct symbols and localized accessible labels',
    (tester) async {
      for (final (state, label, icon) in [
        (TvInputConnection.connected, 'Подключён', Icons.circle),
        (
          TvInputConnection.standby,
          'Подключён · ожидание',
          Icons.pause_circle_filled,
        ),
        (TvInputConnection.disconnected, 'Отключён', Icons.circle_outlined),
        (
          TvInputConnection.unknown,
          'Состояние подключения недоступно',
          Icons.help_outline,
        ),
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('ru'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: TvInputConnectionIndicator(connection: state),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byIcon(icon), findsOneWidget);
        expect(find.byTooltip(label), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.label == label,
          ),
          findsOneWidget,
        );
      }
    },
  );
}
