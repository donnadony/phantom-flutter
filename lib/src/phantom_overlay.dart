import 'dart:async';

import 'package:flutter/material.dart';

import 'core/phantom_button_placement.dart';
import 'phantom_main.dart';
import 'theme/phantom_theme.dart';
import 'ui/phantom_sheet.dart';
import 'ui/phantom_view.dart';
import 'utils/phantom_shake_detector.dart';

const phantomFloatingButtonKey = Key('phantom_floating_button');
const phantomEdgeHandleKey = Key('phantom_edge_handle');

const _buttonSize = 44.0;
const _buttonMargin = 16.0;
const _handleWidth = 18.0;
const _edgeSlop = 6.0;

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

  /// How solid the floating button is drawn, from 0 (invisible) to 1. Apps
  /// that want it out of the way of screenshots and demos fade it; it still
  /// takes taps and drags at any value.
  final double buttonOpacity;

  /// Injected in tests so a shake can be driven without an accelerometer.
  @visibleForTesting
  final PhantomShakeDetector? shakeDetector;

  /// Where the button's place on screen is remembered between launches.
  /// Defaults to SharedPreferences; injected in tests so they touch no disk.
  @visibleForTesting
  final PhantomButtonPlacementStore? placementStore;

  const PhantomOverlay({
    super.key,
    required this.child,
    this.showFloatingButton = true,
    this.theme,
    this.presentation = PhantomPresentation.fullScreen,
    this.initialSheetSize = 0.5,
    this.buttonIcon = Icons.bug_report_rounded,
    this.buttonOpacity = 1,
    this.shakeDetector,
    this.placementStore,
  }) : assert(
         initialSheetSize > 0 && initialSheetSize <= 1,
         'initialSheetSize is a fraction of the screen. At 0 the panel has no '
         'height but its scrim still swallows every tap; above 1 it overflows.',
       );

  @override
  State<PhantomOverlay> createState() => _PhantomOverlayState();
}

class _PhantomOverlayState extends State<PhantomOverlay> {
  Offset _buttonPosition = const Offset(_buttonMargin, 100);
  bool _hasDragged = false;
  bool _phantomOpen = false;
  bool _tuckedLeft = false;
  bool _tucked = false;

  /// Deliberately not persisted. Hiding the button is for getting it out of
  /// the way of the screen underneath, and a restart is then a guaranteed way
  /// back on every platform — including the ones with no accelerometer, where
  /// the shake gesture cannot help.
  bool _buttonHidden = false;

  late final PhantomShakeDetector _shake =
      widget.shakeDetector ?? PhantomShakeDetector();

  late final PhantomButtonPlacementStore _placements =
      widget.placementStore ?? const SharedPreferencesPlacementStore();

  @override
  void initState() {
    super.initState();
    if (widget.theme != null) {
      Phantom.setTheme(widget.theme!);
    }
    Phantom.loadMocks();
    unawaited(_restorePlacement());
  }

  /// The button is drawn at its default place first and moves when the store
  /// answers, rather than waiting: a slow read would otherwise leave the screen
  /// without its way into the panel.
  Future<void> _restorePlacement() async {
    PhantomButtonPlacement? read;
    try {
      read = await _placements.read();
    } on Object {
      return;
    }

    final stored = read;
    if (stored == null || !mounted) return;

    setState(() {
      _buttonPosition = Offset(stored.dx, stored.dy);
      _tucked = stored.tucked;
      _tuckedLeft = stored.tuckedLeft;
    });
  }

  /// Written on every settle, never on every frame of a drag.
  void _rememberPlacement() {
    unawaited(
      _placements
          .write((
            dx: _buttonPosition.dx,
            dy: _buttonPosition.dy,
            tucked: _tucked,
            tuckedLeft: _tuckedLeft,
          ))
          .catchError((Object _) {}),
    );
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
          if (!_phantomOpen && !_buttonHidden && _tucked)
            Positioned(
              left: _tuckedLeft ? 0 : null,
              right: _tuckedLeft ? null : 0,
              top: _buttonPosition.dy,
              child: GestureDetector(
                key: phantomEdgeHandleKey,
                onPanUpdate: (details) {
                  _hasDragged = true;
                  setState(() {
                    _buttonPosition += Offset(0, details.delta.dy);
                  });
                },
                onPanStart: (_) {
                  _hasDragged = false;
                },
                onPanEnd: (_) {
                  if (_hasDragged) {
                    _clampVertically();
                  } else {
                    _untuck();
                  }
                },
                onTap: _untuck,
                child: Opacity(
                  opacity: widget.buttonOpacity,
                  child: _EdgeHandle(
                    theme: widget.theme ?? Phantom.theme,
                    onLeftEdge: _tuckedLeft,
                  ),
                ),
              ),
            ),
          if (!_phantomOpen && !_buttonHidden && !_tucked)
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
                    _settleAfterDrag();
                  } else {
                    _openPhantom();
                  }
                },
                onTap: _openPhantom,
                child: Opacity(
                  opacity: widget.buttonOpacity,
                  child: _FloatingButton(
                    key: phantomFloatingButtonKey,
                    theme: widget.theme ?? Phantom.theme,
                    icon: widget.buttonIcon,
                  ),
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

  void _settleAfterDrag() {
    final size = MediaQuery.of(context).size;
    final pastLeft = _buttonPosition.dx < -_edgeSlop;
    final pastRight = _buttonPosition.dx + _buttonSize > size.width + _edgeSlop;

    if (pastLeft || pastRight) {
      setState(() {
        _tucked = true;
        _tuckedLeft = pastLeft;
        _buttonPosition = Offset(
          pastLeft ? _buttonMargin : size.width - _buttonSize - _buttonMargin,
          _clampedTop(size),
        );
      });
      _rememberPlacement();
      return;
    }

    _snapToEdge();
  }

  void _snapToEdge() {
    final size = MediaQuery.of(context).size;
    final midX = size.width / 2;
    setState(() {
      _buttonPosition = Offset(
        _buttonPosition.dx < midX
            ? _buttonMargin
            : size.width - _buttonSize - _buttonMargin,
        _clampedTop(size),
      );
    });
    _rememberPlacement();
  }

  void _clampVertically() {
    final size = MediaQuery.of(context).size;
    setState(() {
      _buttonPosition = Offset(_buttonPosition.dx, _clampedTop(size));
    });
    _rememberPlacement();
  }

  double _clampedTop(Size size) {
    return _buttonPosition.dy.clamp(50.0, size.height - 100);
  }

  void _untuck() {
    if (!mounted) return;
    setState(() => _tucked = false);
    _rememberPlacement();
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

class _EdgeHandle extends StatelessWidget {
  final PhantomTheme theme;
  final bool onLeftEdge;

  const _EdgeHandle({required this.theme, required this.onLeftEdge});

  @override
  Widget build(BuildContext context) {
    final rounded = Radius.circular(_buttonSize / 2);
    return Container(
      width: _handleWidth,
      height: _buttonSize,
      decoration: BoxDecoration(
        color: theme.primaryContainer,
        borderRadius: BorderRadius.only(
          topRight: onLeftEdge ? rounded : Radius.zero,
          bottomRight: onLeftEdge ? rounded : Radius.zero,
          topLeft: onLeftEdge ? Radius.zero : rounded,
          bottomLeft: onLeftEdge ? Radius.zero : rounded,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        onLeftEdge ? Icons.chevron_right : Icons.chevron_left,
        color: theme.onPrimary,
        size: 16,
      ),
    );
  }
}

class _FloatingButton extends StatelessWidget {
  final PhantomTheme theme;
  final IconData icon;

  const _FloatingButton({super.key, required this.theme, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _buttonSize,
      height: _buttonSize,
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
