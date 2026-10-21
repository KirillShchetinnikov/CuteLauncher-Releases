// Full capabilities for existing TV fixtures; compatibility tests override individual actions.
const supportedAdbCompatibility = {
  'system': 'Android TV',
  'actions': {
    'home': true,
    'restore': true,
    'overlay': true,
    'usage': true,
    'writeSettings': true,
    'notifications': true,
    'watchNext': true,
    'accessibility': true,
    'disableAccessibility': true,
    'restoreAccessibility': true,
    'disableSystem': true,
    'enableSystem': true,
  },
  'disableTargets': {
    'com.google.android.tvlauncher': true,
    'com.google.android.apps.tv.launcherx': true,
  },
};
