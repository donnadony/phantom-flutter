import 'package:flutter/material.dart';

import '../theme/phantom_theme.dart';
import 'logs/phantom_logs_page.dart';
import 'network/phantom_network_page.dart';

class PhantomView extends StatelessWidget {
  final VoidCallback? onClose;

  const PhantomView({super.key, this.onClose});

  @override
  Widget build(BuildContext context) {
    final theme = PhantomThemeProvider.of(context);

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.background,
        foregroundColor: theme.onBackground,
        title: Text(
          'Phantom',
          style: TextStyle(
            color: theme.onBackground,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.close, color: theme.onBackgroundVariant),
          onPressed: onClose ?? () => Navigator.of(context).pop(),
        ),
      ),
      body: PhantomViewBody(onClose: onClose),
    );
  }
}

class PhantomViewBody extends StatelessWidget {
  final VoidCallback? onClose;

  const PhantomViewBody({super.key, this.onClose});

  @override
  Widget build(BuildContext context) {
    final theme = PhantomThemeProvider.of(context);

    final items = [
      _MenuItem(title: 'Logs', icon: Icons.description_outlined, destination: const PhantomLogsPage()),
      _MenuItem(title: 'Network', icon: Icons.language, destination: const PhantomNetworkPage()),
      _MenuItem(title: 'Mock Services', icon: Icons.sensors, destination: null),
      _MenuItem(title: 'Configuration', icon: Icons.settings_outlined, destination: null),
      _MenuItem(title: 'Device Info', icon: Icons.phone_iphone, destination: null),
      _MenuItem(title: 'SharedPreferences', icon: Icons.storage_outlined, destination: null),
      _MenuItem(title: 'Localization', icon: Icons.public, destination: null),
    ];

    return SingleChildScrollView(
      child: Column(
        children: [
          for (final item in items) ...[
            _phantomRow(context, item: item, theme: theme),
            Divider(height: 1, color: theme.outlineVariant, indent: 16, endIndent: 16),
          ],
        ],
      ),
    );
  }

  Widget _phantomRow(BuildContext context, {required _MenuItem item, required PhantomTheme theme}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: item.destination != null
          ? () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PhantomThemeProvider(
                    theme: theme,
                    child: item.destination!,
                  ),
                ),
              );
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Icon(item.icon, color: theme.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.title,
                style: TextStyle(
                  color: item.destination != null ? theme.onBackground : theme.onBackgroundVariant,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: theme.onBackgroundVariant, size: 20),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final String title;
  final IconData icon;
  final Widget? destination;

  const _MenuItem({required this.title, required this.icon, this.destination});
}
