class RemoteMapping {
  final int keyCode;
  final bool enabled;
  final String action, target, trigger, name;
  String get slot => '$keyCode:$trigger';
  const RemoteMapping({
    required this.keyCode,
    this.enabled = true,
    this.action = 'home',
    this.target = '',
    this.trigger = 'press',
    this.name = '',
  });
  factory RemoteMapping.fromMap(Map value) => RemoteMapping(
    name: value['name'] as String? ?? '',
    keyCode: value['keyCode'] as int,
    enabled: value['enabled'] as bool,
    action: value['action'] as String,
    target: value['target'] as String,
    trigger: value['trigger'] as String? ?? 'press',
  );
  Map<String, dynamic> toMap() => {
    'name': name,
    'keyCode': keyCode,
    'enabled': enabled,
    'action': action,
    'target': target,
    'trigger': trigger,
  };
  RemoteMapping copyWith({
    bool? enabled,
    String? action,
    String? target,
    String? trigger,
  }) => RemoteMapping(
    keyCode: keyCode,
    name: name,
    enabled: enabled ?? this.enabled,
    action: action ?? this.action,
    target: target ?? this.target,
    trigger: trigger ?? this.trigger,
  );
}

String? remoteWebhookFromText(String source) {
  final value = source
      .replaceFirst(RegExp(r'^\uFEFF'), '')
      .replaceAll(RegExp(r'[\r\n\u0085\u2028\u2029]'), '')
      .trim();
  return remoteWebhookValid(value) ? value : null;
}

bool remoteWebhookValid(String value) {
  if (value.length > 4096 ||
      RegExp(r"\s").hasMatch(value) ||
      value.codeUnits.any((code) => code < 32 || code == 127)) {
    return false;
  }
  final uri = Uri.tryParse(value);
  if (uri == null ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasFragment ||
      uri.path.isEmpty ||
      uri.port == 0 ||
      uri.port > 65535) {
    return false;
  }
  if (uri.scheme == 'https') return true;
  if (uri.scheme != 'http') return false;
  final host = uri.host.toLowerCase();
  if (host == 'localhost' || host.endsWith('.local') || host.endsWith('.lan')) {
    return true;
  }
  final parts = host.split('.').map(int.tryParse).toList();
  if (parts.length != 4 ||
      parts.any((value) => value == null || value < 0 || value > 255)) {
    return false;
  }
  return parts[0] == 10 ||
      parts[0] == 127 ||
      parts[0] == 192 && parts[1] == 168 ||
      parts[0] == 172 && (parts[1] ?? 0) >= 16 && (parts[1] ?? 0) <= 31;
}

class RemoteMappingConfiguration {
  final bool enabled;
  final List<RemoteMapping> bindings;
  const RemoteMappingConfiguration({
    this.enabled = false,
    this.bindings = const [],
  });
  factory RemoteMappingConfiguration.fromMap(Map value) =>
      RemoteMappingConfiguration(
        enabled: value['enabled'] as bool,
        bindings: List.unmodifiable(
          (value['bindings'] as List).map(
            (entry) => RemoteMapping.fromMap(entry as Map),
          ),
        ),
      );
  Map<String, dynamic> toMap() => {
    'enabled': enabled,
    'bindings': bindings.map((value) => value.toMap()).toList(),
  };
  RemoteMappingConfiguration replace(RemoteMapping value) =>
      RemoteMappingConfiguration(
        enabled: enabled,
        bindings: [
          for (final old in bindings)
            if (old.slot != value.slot) old,
          value,
        ],
      );
  RemoteMappingConfiguration remove(int keyCode, [String trigger = 'press']) =>
      RemoteMappingConfiguration(
        enabled: enabled,
        bindings: bindings
            .where((value) => value.slot != '$keyCode:$trigger')
            .toList(),
      );
}
