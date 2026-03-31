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
  bool _hasDragged = false;
  bool _phantomOpen = false;

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
          if (!_phantomOpen)
            Positioned(
              left: _buttonPosition.dx,
              top: _buttonPosition.dy,
              child: GestureDetector(
                onPanStart: (_) {
                  _hasDragged = false;
                },
                onPanUpdate: (details) {
                  _hasDragged = true;
                  setState(() {
                    _buttonPosition += details.delta;
                  });
                },
                onPanEnd: (_) {
                  if (_hasDragged) {
                    _snapToEdge();
                  } else {
                    _openPhantom();
                  }
                },
                onTap: _openPhantom,
                child: _FloatingButton(theme: widget.theme ?? Phantom.theme),
              ),
            ),
          if (_phantomOpen)
            Positioned.fill(
              child: _PhantomApp(
                theme: widget.theme ?? Phantom.theme,
                onClose: () => setState(() => _phantomOpen = false),
              ),
            ),
        ],
      ),
    );
  }

  void _snapToEdge() {
    final size = MediaQuery.of(context).size;
    final midX = size.width / 2;
    setState(() {
      _buttonPosition = Offset(
        _buttonPosition.dx < midX ? 16 : size.width - 60,
        _buttonPosition.dy.clamp(50.0, size.height - 100),
      );
    });
  }

  void _openPhantom() {
    setState(() => _phantomOpen = true);
  }
}

class _PhantomApp extends StatelessWidget {
  final PhantomTheme theme;
  final VoidCallback onClose;

  const _PhantomApp({required this.theme, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return PhantomThemeProvider(
      theme: theme,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: PhantomView(onClose: onClose),
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
