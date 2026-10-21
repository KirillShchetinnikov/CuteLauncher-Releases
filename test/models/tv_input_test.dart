import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/models/tv_input.dart';

void main() {
  TvInput source(
    String id,
    String label, {
    String? parent,
    String? custom,
    String? name,
  }) => TvInput.fromMap({
    'id': id,
    'label': name ?? label,
    'type': 1007,
    'parentId': parent,
    'customLabel': custom,
  });

  test(
    'CEC replaces its physical port label, retaining stable ids and ordering',
    () {
      final inputs = [
        source('hdmi4', 'HDMI 4'),
        source('xbox', 'XBOX', parent: 'hdmi2'),
        source('hdmi2', 'HDMI 2'),
        source('hdmi1', 'HDMI 1'),
        source('hdmi3', 'HDMI 3'),
      ];
      final result = TvInput.ordered(inputs);
      expect(result.map((i) => i.label), [
        'HDMI 1',
        'XBOX',
        'HDMI 3',
        'HDMI 4',
      ]);
      expect(result[1].id, 'hdmi2');
      expect(result[1].matchesId('hdmi2'), isTrue);
      expect(result[1].matchesId('xbox'), isTrue);
      expect(result[1].matchesId('hdmi3'), isFalse);
      expect(
        TvInput.ordered(result).map((i) => i.label),
        result.map((i) => i.label),
      );
      expect(
        TvInput.ordered(inputs.where((i) => i.id != 'xbox'))
            .map((i) => i.label),
        ['HDMI 1', 'HDMI 2', 'HDMI 3', 'HDMI 4'],
      );
      expect(inputs, hasLength(5));
    },
  );

  test('names do not determine port identity or numeric ordering', () {
    final result = TvInput.ordered([
      source('hdmi10', 'HDMI 10', custom: 'Receiver'),
      source('hdmi2', 'HDMI 2', custom: 'Console'),
      source('other', 'HDMI 3', parent: 'missing', custom: 'XBOX'),
      source('child', 'Unknown', parent: 'hdmi2', name: ' XBOX '),
    ]);
    expect(result.map((i) => i.label), ['XBOX', 'XBOX', 'Receiver']);
    expect(result.map((i) => i.id), ['hdmi2', 'other', 'hdmi10']);
    expect(
      TvInput.ordered([source('a', 'HDMI 1'), source('b', 'HDMI 1')]),
      hasLength(2),
    );
  });

  test(
    'blank names fall back and multiple logical devices remain selectable',
    () {
      final parent = source('port', 'HDMI 2');
      expect(
        TvInput.ordered([
          parent,
          source('child', '', parent: 'port', name: ' ', custom: ' '),
        ]).single.label,
        'HDMI 2',
      );
      expect(
        TvInput.ordered([parent, source('child', 'HDMI 2', parent: 'port')])
            .single
            .label,
        'HDMI 2',
      );
      expect(
        TvInput.ordered([
          parent,
          source('child', 'HDMI 2 Console', parent: 'port'),
        ]).single.label,
        'HDMI 2 Console',
      );
      final devices = [
        parent,
        source('xbox', 'XBOX', parent: 'port'),
        source('player', 'Player', parent: 'port'),
      ];
      expect(
        TvInput.ordered(devices).map((i) => i.id),
        containsAll(['xbox', 'player']),
      );
      expect(TvInput.ordered([
        parent,
        source('receiver', 'Receiver', parent: 'port'),
        source('console', 'Console', parent: 'receiver'),
      ]).map((i) => i.id), ['port', 'receiver', 'console']);
      expect(
        source('p', 'HDMI 2', custom: ' My name ', name: 'CEC name').label,
        'My name',
      );
    },
  );

  TvInput hdmi(String label) =>
      TvInput(id: label, label: label, type: TvInputType.hdmi);

  test('HDMI ports are numeric in both full and HDMI-only lists', () {
    final av = TvInput(id: 'av', label: 'AV', type: TvInputType.av);
    final inputs = [
      hdmi('HDMI 4'),
      av,
      hdmi('HDMI2'),
      hdmi('HDMI 3 (ARC)'),
      hdmi('hdmi 1'),
      hdmi('HDMI 10'),
    ];
    final ordered = TvInput.ordered(inputs);
    expect(ordered.map((input) => input.label), [
      'hdmi 1',
      'AV',
      'HDMI2',
      'HDMI 3 (ARC)',
      'HDMI 4',
      'HDMI 10',
    ]);
    expect(
      TvInput.ordered(inputs.where((input) => input.type == TvInputType.hdmi)),
      ordered.where((input) => input.type == TvInputType.hdmi),
    );
    expect(inputs.first.label, 'HDMI 4');
  });

  test('unnumbered and equal ports retain their original relative order', () {
    final inputs = [
      hdmi('Console'),
      hdmi('HDMI 2'),
      hdmi('HDMI 1 ARC'),
      hdmi('HDMI 1'),
      hdmi('Player'),
    ];
    expect(TvInput.ordered(inputs).map((input) => input.label), [
      'HDMI 1 ARC',
      'HDMI 1',
      'HDMI 2',
      'Console',
      'Player',
    ]);
    expect(TvInput.ordered([]), isEmpty);
  });
}
