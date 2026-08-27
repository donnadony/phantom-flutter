import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../../theme/phantom_theme.dart';

class PhantomDeviceInfoPage extends StatefulWidget {
  const PhantomDeviceInfoPage({super.key});

  @override
  State<PhantomDeviceInfoPage> createState() => _PhantomDeviceInfoPageState();
}

class _PhantomDeviceInfoPageState extends State<PhantomDeviceInfoPage> {
  final Map<String, List<_InfoItem>> _sections = {};
  String? _copiedKey;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final deviceInfo = DeviceInfoPlugin();

    final appSection = [
      _InfoItem('App Name', packageInfo.appName),
      _InfoItem('Package Name', packageInfo.packageName),
      _InfoItem('Version', packageInfo.version),
      _InfoItem('Build Number', packageInfo.buildNumber),
    ];

    List<_InfoItem> deviceSection;
    List<_InfoItem> screenSection;

    if (Platform.isIOS) {
      final ios = await deviceInfo.iosInfo;
      deviceSection = [
        _InfoItem('Device', ios.name),
        _InfoItem('Model', ios.model),
        _InfoItem('System Name', ios.systemName),
        _InfoItem('System Version', ios.systemVersion),
        _InfoItem('Identifier', ios.identifierForVendor ?? 'N/A'),
        _InfoItem('Physical Device', ios.isPhysicalDevice ? 'Yes' : 'No'),
      ];
    } else {
      final android = await deviceInfo.androidInfo;
      deviceSection = [
        _InfoItem('Device', android.device),
        _InfoItem('Model', android.model),
        _InfoItem('Brand', android.brand),
        _InfoItem('Android Version', android.version.release),
        _InfoItem('SDK Level', android.version.sdkInt.toString()),
        _InfoItem('Physical Device', android.isPhysicalDevice ? 'Yes' : 'No'),
      ];
    }

    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final size = view.physicalSize;
    final ratio = view.devicePixelRatio;
    screenSection = [
      _InfoItem('Screen Size', '${(size.width / ratio).toStringAsFixed(0)} x ${(size.height / ratio).toStringAsFixed(0)}'),
      _InfoItem('Pixel Ratio', '${ratio.toStringAsFixed(1)}x'),
      _InfoItem('Physical Pixels', '${size.width.toStringAsFixed(0)} x ${size.height.toStringAsFixed(0)}'),
    ];

    final storageSection = await _storageItems();
    final memorySection = _memoryItems();

    if (!mounted) return;
    setState(() {
      _sections['App'] = appSection;
      _sections['Device'] = deviceSection;
      _sections['Screen'] = screenSection;
      if (storageSection.isNotEmpty) _sections['Storage'] = storageSection;
      _sections['Memory'] = memorySection;
    });
  }

  /// Per-directory app storage usage.
  ///
  /// Device-wide free/total disk is intentionally absent: Dart exposes no
  /// cross-platform API for it, and pulling in a plugin just for that number is
  /// not worth it. What the app itself occupies is the actionable figure anyway.
  Future<List<_InfoItem>> _storageItems() async {
    final items = <_InfoItem>[];

    Future<void> add(String label, Future<Directory?> Function() resolve) async {
      try {
        final dir = await resolve();
        if (dir == null || !dir.existsSync()) return;
        items.add(_InfoItem(label, _formatBytes(_directorySize(dir))));
      } catch (_) {
        // Directory unavailable on this platform.
      }
    }

    await add('Documents', getApplicationDocumentsDirectory);
    await add('Application Support', getApplicationSupportDirectory);
    await add('Cache', getApplicationCacheDirectory);
    await add('Temporary', getTemporaryDirectory);
    return items;
  }

  List<_InfoItem> _memoryItems() {
    return [
      _InfoItem('Current RSS', _formatBytes(ProcessInfo.currentRss)),
      _InfoItem('Peak RSS', _formatBytes(ProcessInfo.maxRss)),
    ];
  }

  /// Recursive size of [dir]. Unreadable entries are skipped rather than
  /// aborting the whole walk.
  int _directorySize(Directory dir) {
    var total = 0;
    try {
      for (final entity in dir.listSync(recursive: true, followLinks: false)) {
        if (entity is! File) continue;
        try {
          total += entity.lengthSync();
        } catch (_) {}
      }
    } catch (_) {}
    return total;
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = PhantomThemeProvider.of(context);

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.background,
        foregroundColor: theme.onBackground,
        title: Text('Device Info', style: TextStyle(color: theme.onBackground, fontWeight: FontWeight.bold)),
      ),
      body: _sections.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: _sections.entries.map((section) {
                return _buildSection(section.key, section.value, theme);
              }).toList(),
            ),
    );
  }

  Widget _buildSection(String title, List<_InfoItem> items, PhantomTheme theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Text(title, style: TextStyle(color: theme.primary, fontSize: 13, fontWeight: FontWeight.bold)),
          ),
          ...items.map((item) => _infoRow(item, theme)),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _infoRow(_InfoItem item, PhantomTheme theme) {
    final copied = _copiedKey == item.label;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Clipboard.setData(ClipboardData(text: item.value));
        setState(() => _copiedKey = item.label);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _copiedKey = null);
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(item.label, style: TextStyle(color: theme.onBackgroundVariant, fontSize: 13)),
            ),
            if (copied)
              Icon(Icons.check, color: theme.success, size: 14)
            else
              Flexible(
                child: Text(
                  item.value,
                  style: TextStyle(color: theme.onBackground, fontSize: 13, fontFamily: 'monospace'),
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoItem {
  final String label;
  final String value;
  const _InfoItem(this.label, this.value);
}
