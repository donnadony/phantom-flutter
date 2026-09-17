import 'package:flutter/material.dart';

import '../phantom_main.dart';
import '../theme/phantom_theme.dart';

class PhantomView extends StatelessWidget {
  final VoidCallback? onClose;

  /// Hides or restores the host overlay's floating button.
  ///
  /// Null when there is no floating button to act on — `Phantom.show(context)`
  /// pushes the panel with no overlay behind it — and the row is left out.
  /// Whether the floating button is currently hidden, which decides whether the
  /// row offers to hide or to restore it.
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
              theme: theme,
              title: feature.title,
              icon: feature.icon,
              onTap: () => _push(context, theme, feature.destination),
            ),
            _divider(theme),
          ],
          for (final entry in Phantom.customEntries) ...[
            _row(
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
        builder: (_) => PhantomThemeProvider(theme: theme, child: destination),
      ),
    );
  }

  Widget _row({
    required PhantomTheme theme,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    String? subtitle,
    bool showChevron = true,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: theme.onBackground,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: theme.onBackgroundVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (showChevron)
              Icon(
                Icons.chevron_right,
                color: theme.onBackgroundVariant,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
