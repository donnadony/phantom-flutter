import 'package:flutter/material.dart';

import '../../ui/config/phantom_config_page.dart';
import '../../ui/deeplink/phantom_deeplink_page.dart';
import '../../ui/device_info/phantom_device_info_page.dart';
import '../../ui/files/phantom_file_browser_page.dart';
import '../../ui/localization/phantom_localization_page.dart';
import '../../ui/logs/phantom_logs_page.dart';
import '../../ui/mock/phantom_mock_list_page.dart';
import '../../ui/network/phantom_network_page.dart';
import '../../ui/shared_prefs/phantom_shared_prefs_page.dart';

/// The debug modules Phantom can show in its main menu.
///
/// Pass a subset to [Phantom.setFeatures] to control which ones are visible.
enum PhantomFeature {
  logs,
  network,
  mockServices,
  configuration,
  deviceInfo,
  sharedPreferences,
  localization,
  fileBrowser,
  deepLink;

  String get title {
    switch (this) {
      case PhantomFeature.logs:
        return 'Logs';
      case PhantomFeature.network:
        return 'Network';
      case PhantomFeature.mockServices:
        return 'Mock Services';
      case PhantomFeature.configuration:
        return 'Configuration';
      case PhantomFeature.deviceInfo:
        return 'Device Info';
      case PhantomFeature.sharedPreferences:
        return 'SharedPreferences';
      case PhantomFeature.localization:
        return 'Localization';
      case PhantomFeature.fileBrowser:
        return 'File Browser';
      case PhantomFeature.deepLink:
        return 'Deep Link Tester';
    }
  }

  IconData get icon {
    switch (this) {
      case PhantomFeature.logs:
        return Icons.description_outlined;
      case PhantomFeature.network:
        return Icons.language;
      case PhantomFeature.mockServices:
        return Icons.sensors;
      case PhantomFeature.configuration:
        return Icons.settings_outlined;
      case PhantomFeature.deviceInfo:
        return Icons.phone_iphone;
      case PhantomFeature.sharedPreferences:
        return Icons.storage_outlined;
      case PhantomFeature.localization:
        return Icons.public;
      case PhantomFeature.fileBrowser:
        return Icons.folder_outlined;
      case PhantomFeature.deepLink:
        return Icons.link;
    }
  }

  Widget get destination {
    switch (this) {
      case PhantomFeature.logs:
        return const PhantomLogsPage();
      case PhantomFeature.network:
        return const PhantomNetworkPage();
      case PhantomFeature.mockServices:
        return const PhantomMockListPage();
      case PhantomFeature.configuration:
        return const PhantomConfigPage();
      case PhantomFeature.deviceInfo:
        return const PhantomDeviceInfoPage();
      case PhantomFeature.sharedPreferences:
        return const PhantomSharedPrefsPage();
      case PhantomFeature.localization:
        return const PhantomLocalizationPage();
      case PhantomFeature.fileBrowser:
        return const PhantomFileBrowserPage();
      case PhantomFeature.deepLink:
        return const PhantomDeepLinkPage();
    }
  }
}

/// A caller-supplied row appended to the bottom of Phantom's main menu.
class PhantomCustomEntry {
  final String title;
  final IconData icon;
  final VoidCallback action;

  const PhantomCustomEntry({
    required this.title,
    required this.icon,
    required this.action,
  });
}
