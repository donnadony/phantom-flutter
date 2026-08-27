import 'package:flutter/material.dart';

import '../phantom_main.dart';
import '../theme/phantom_theme.dart';

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

    return SingleChildScrollView(
      child: Column(
        children: [
          for (final feature in Phantom.features) ...[
            _row(
              context,
              theme: theme,
              title: feature.title,
              icon: feature.icon,
              onTap: () => _push(context, theme, feature.destination),
            ),
            _divider(theme),
          ],
          for (final entry in Phantom.customEntries) ...[
            _row(
              context,
              theme: theme,
              title: entry.title,
              icon: entry.icon,
              onTap: entry.action,
            ),
            _divider(theme),
          ],
        ],
      ),
    );
  }

  Widget _divider(PhantomTheme theme) => Divider(
        height: 1,
        color: theme.outlineVariant,
        indent: 16,
        endIndent: 16,
      );

  void _push(BuildContext context, PhantomTheme theme, Widget destination) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PhantomThemeProvider(
          theme: theme,
          child: destination,
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context, {
    required PhantomTheme theme,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Icon(icon, color: theme.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: theme.onBackground,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.chevron_right,
                color: theme.onBackgroundVariant, size: 20),
          ],
        ),
      ),
    );
  }
}
