import 'package:flutter/material.dart';

import 'phantom_main.dart';
import 'theme/phantom_theme.dart';
import 'ui/phantom_sheet.dart';
import 'ui/phantom_view.dart';
import 'utils/phantom_shake_detector.dart';

class PhantomOverlay extends StatefulWidget {
  final Widget child;
  final bool showFloatingButton;
  final PhantomTheme? theme;

  /// Whether the panel covers the app or rises as a draggable sheet.
  /// Defaults to [PhantomPresentation.fullScreen] so existing callers see no
  /// change.
  ///
  /// Governs the floating button only. `Phantom.show(context)` always pushes
  /// the panel full screen on the host navigator.
  final PhantomPresentation presentation;

  /// Fraction of the screen the sheet opens at. Ignored when [presentation] is
  /// [PhantomPresentation.fullScreen].
  final double initialSheetSize;

  /// The glyph on the floating button. The bug badge by default; apps that
  /// already spend that shape on something else can pass their own.
  final IconData buttonIcon;

  /// Injected in tests so a shake can be driven without an accelerometer.
  @visibleForTesting
  final PhantomShakeDetector? shakeDetector;

  const PhantomOverlay({
    super.key,
    required this.child,
    this.showFloatingButton = true,
    this.theme,
    this.presentation = PhantomPresentation.fullScreen,
    this.initialSheetSize = 0.5,
    this.buttonIcon = Icons.bug_report_rounded,
    this.shakeDetector,
  }) : assert(
         initialSheetSize > 0 && initialSheetSize <= 1,
         'initialSheetSize is a fraction of the screen. At 0 the panel has no '
         'height but its scrim still swallows every tap; above 1 it overflows.',
       );

  @override
  State<PhantomOverlay> createState() => _PhantomOverlayState();
}

class _PhantomOverlayState extends State<PhantomOverlay> {
  Offset _buttonPosition = const Offset(16, 100);
  bool _hasDragged = false;
  bool _phantomOpen = false;

  /// Deliberately not persisted. Hiding the button is for getting it out of
  /// the way of the screen underneath, and a restart is then a guaranteed way
  /// back on every platform — including the ones with no accelerometer, where
  /// the shake gesture cannot help.
  bool _buttonHidden = false;

  late final PhantomShakeDetector _shake =
      widget.shakeDetector ?? PhantomShakeDetector();

  @override
  void initState() {
    super.initState();
    if (widget.theme != null) {
      Phantom.setTheme(widget.theme!);
    }
    Phantom.loadMocks();
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  /// The sensor runs only while the button is hidden and the panel is closed —
  /// the one window where a shake is the only way back in.
  void _syncShakeListener() {
    final needed = _buttonHidden && !_phantomOpen;
    if (needed && !_shake.isRunning) {
      _shake.start(_openPhantom);
    } else if (!needed && _shake.isRunning) {
      _shake.stop();
    }
  }

  void _toggleButton() {
    setState(() => _buttonHidden = !_buttonHidden);
    _syncShakeListener();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showFloatingButton) return widget.child;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          widget.child,
          if (!_phantomOpen && !_buttonHidden)
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
                child: _FloatingButton(
                  theme: widget.theme ?? Phantom.theme,
                  icon: widget.buttonIcon,
                ),
              ),
            ),
          if (_phantomOpen)
            Positioned.fill(
              child: switch (widget.presentation) {
                PhantomPresentation.fullScreen => _PhantomApp(
                  theme: widget.theme ?? Phantom.theme,
                  onClose: _closePhantom,
                  onToggleButton: _toggleButton,
                  buttonHidden: _buttonHidden,
                ),
                PhantomPresentation.sheet => PhantomSheet(
                  theme: widget.theme ?? Phantom.theme,
                  initialSize: widget.initialSheetSize,
                  onClose: _closePhantom,
                  onToggleButton: _toggleButton,
                  buttonHidden: _buttonHidden,
                ),
              },
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
    if (!mounted) return;
    setState(() => _phantomOpen = true);
    _syncShakeListener();
  }

  void _closePhantom() {
    if (!mounted) return;
    setState(() => _phantomOpen = false);
    _syncShakeListener();
  }
}

class _PhantomApp extends StatelessWidget {
  final PhantomTheme theme;
  final VoidCallback onClose;
  final VoidCallback onToggleButton;
  final bool buttonHidden;

  const _PhantomApp({
    required this.theme,
    required this.onClose,
    required this.onToggleButton,
    required this.buttonHidden,
  });

  @override
  Widget build(BuildContext context) {
    return PhantomThemeProvider(
      theme: theme,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: PhantomView(
          onClose: onClose,
          onToggleButton: onToggleButton,
          buttonHidden: buttonHidden,
        ),
      ),
    );
  }
}

class _FloatingButton extends StatelessWidget {
  final PhantomTheme theme;
  final IconData icon;

  const _FloatingButton({required this.theme, required this.icon});

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
      child: Icon(icon, color: theme.onPrimary, size: 22),
    );
  }
}
