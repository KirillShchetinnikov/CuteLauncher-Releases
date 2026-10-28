/// Fixed recovery outcomes only; no shell output, component lists, ports or keys.
Map<String, Object> permissionRecoveryDiagnostics(Map raw) {
  const outcomes = {
    'not_checked', 'healthy', 'resolved_or_revoked', 'retry_pending', 'restored_or_revoked',
    'expired', 'exhausted', 'check_unavailable', 'adb_not_configured', 'adb_unavailable',
    'adb_authorization', 'unsupported_user', 'command_rejected', 'permission_rejected',
    'manual_disable', 'connected', 'disabled', 'binding_grace', 'reconnected', 'awaiting_connection',
    'update_recovery_pending',
  };
  const permissions = {'accessibility', 'notifications', 'overlay', 'usage', 'writeSettings', 'watchNext'};
  return {
    for (final key in ['status', 'health'])
      key: outcomes.contains(raw[key]) ? raw[key] as String : 'unknown',
    if (raw['attempts'] is int && raw['attempts'] >= 0 && raw['attempts'] <= 5)
      'attempts': raw['attempts'] as int,
    for (final key in ['retryAt', 'deadline', 'lastChecked', 'healthRetryAt'])
      if (raw[key] is int && raw[key] >= 0) key: raw[key] as int,
    'pending': raw['pending'] is List
        ? (raw['pending'] as List).whereType<String>().where(permissions.contains).toSet().toList()
        : <String>[],
  };
}
