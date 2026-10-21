import 'dart:async';
import 'dart:io';

import '../../cloud_account.dart';
import '../../l10n/app_localizations.dart';

String? cloudErrorMessage(
  AppLocalizations l,
  Object error, {
  bool drive = false,
}) => switch (error) {
  CloudBackupException(code: 'cancelled') => null,
  CloudBackupException(code: 'configuration') =>
    drive ? l.driveConfigurationError : l.cloudConfigurationError,
  CloudBackupException(code: 'authorization') => l.cloudAuthorizationError,
  CloudBackupException(code: 'expired') when drive => l.driveCodeExpired,
  CloudBackupException(code: 'missing') => l.cloudMissingError,
  CloudBackupException(code: 'unsupported' || 'redirect') when drive =>
    l.cloudFailed,
  CloudBackupException(code: 'unsupported' || 'redirect') =>
    l.cloudUnsupportedError,
  CloudBackupException(code: 'timeout' || 'network') ||
  TimeoutException() ||
  SocketException() => l.cloudNetworkError,
  CloudBackupException(code: 'storage') => l.cloudStorageError,
  _ => l.cloudFailed,
};
