import 'package:flutter/material.dart';

import '../theme/phantom_theme.dart';
import 'logs/phantom_logs_page.dart';
import 'network/phantom_network_page.dart';

class PhantomView extends StatelessWidget {
  const PhantomView({super.key});

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
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _phantomRow(
            context,
            title: 'Logs',
            icon: Icons.article_outlined,
            destination: const PhantomLogsPage(),
            theme: theme,
          ),
          const SizedBox(height: 8),
          _phantomRow(
            context,
            title: 'Network',
            icon: Icons.wifi_outlined,
            destination: const PhantomNetworkPage(),
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _phantomRow(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget destination,
    required PhantomTheme theme,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PhantomThemeProvider(
              theme: theme,
              child: destination,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.tint, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: theme.onBackground,
                  fontSize: 15,
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
