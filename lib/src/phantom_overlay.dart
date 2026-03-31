import 'package:flutter/material.dart';

import 'phantom_main.dart';
import 'theme/phantom_theme.dart';
import 'ui/phantom_view.dart';

class PhantomOverlay extends StatefulWidget {
  final Widget child;
  final bool showFloatingButton;
  final PhantomTheme? theme;

  const PhantomOverlay({
    super.key,
    required this.child,
    this.showFloatingButton = true,
    this.theme,
  });

  @override
  State<PhantomOverlay> createState() => _PhantomOverlayState();
}

class _PhantomOverlayState extends State<PhantomOverlay> {
  Offset _buttonPosition = const Offset(16, 100);
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    if (widget.theme != null) {
      Phantom.setTheme(widget.theme!);
    }
    Phantom.loadMocks();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showFloatingButton) return widget.child;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          widget.child,
          Positioned(
            left: _buttonPosition.dx,
            top: _buttonPosition.dy,
            child: GestureDetector(
              onPanStart: (_) => _isDragging = true,
              onPanUpdate: (details) {
                setState(() {
                  _buttonPosition += details.delta;
                });
              },
              onPanEnd: (_) {
                _isDragging = false;
                _snapToEdge(context);
              },
              onTap: () {
                if (!_isDragging) _openPhantom(context);
              },
              child: _FloatingButton(theme: widget.theme ?? Phantom.theme),
            ),
          ),
        ],
      ),
    );
  }

  void _snapToEdge(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final midX = screenWidth / 2;
    setState(() {
      _buttonPosition = Offset(
        _buttonPosition.dx < midX ? 16 : screenWidth - 60,
        _buttonPosition.dy.clamp(50, MediaQuery.of(context).size.height - 100),
      );
    });
  }

  void _openPhantom(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => PhantomThemeProvider(
          theme: widget.theme ?? Phantom.theme,
          child: const PhantomView(),
        ),
      ),
    );
  }
}

class _FloatingButton extends StatelessWidget {
  final PhantomTheme theme;

  const _FloatingButton({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: theme.primaryContainer,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        Icons.bug_report_rounded,
        color: theme.onPrimary,
        size: 22,
      ),
    );
  }
}
