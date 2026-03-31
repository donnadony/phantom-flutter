import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

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

    setState(() {
      _sections['App'] = appSection;
      _sections['Device'] = deviceSection;
      _sections['Screen'] = screenSection;
    });
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
