import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/phantom_theme.dart';
import 'phantom_view.dart';

/// How the debug panel arrives once the floating button is tapped.
enum PhantomPresentation {
  /// Covers the app. The original behaviour, and still the default so that
  /// existing callers see no change.
  fullScreen,

  /// Rises to part of the screen and can be dragged up to fill it. Leaves the
  /// app visible behind it, which is the point: most debugging is comparing
  /// what the screen shows against what the request actually returned.
  sheet,
}

/// The debug panel as a draggable sheet.
///
/// Deliberately not `DraggableScrollableSheet`: that widget resizes by driving
/// the scroll controller of the scrollable inside it, so every page the panel
/// can push — logs, network, each detail view — would have to accept and
/// forward that controller. Dragging a handle keeps the resize in one place and
/// leaves each page free to scroll the way it already does.
class PhantomSheet extends StatefulWidget {
  const PhantomSheet({
    super.key,
    required this.theme,
    required this.onClose,
    this.onToggleButton,
    this.buttonHidden = false,
    this.initialSize = 0.5,
    this.minSize = 0.25,
    this.maxSize = 1.0,
  }) : assert(
         initialSize >= minSize,
         'initialSize must be at least minSize, or the sheet opens already '
         'below its close threshold and dismisses on the first touch.',
       ),
       assert(
         maxSize >= initialSize,
         'maxSize must be at least initialSize.',
       ),
       assert(
         maxSize <= 1.0 && minSize > 0,
         'Sizes are fractions of the screen, between 0 and 1.',
       );

  final PhantomTheme theme;
  final VoidCallback onClose;

  /// Forwarded to [PhantomView] so the panel can hide the host's floating
  /// button. Null when there is none to act on.
  final VoidCallback? onToggleButton;
  final bool buttonHidden;

  /// Fraction of the screen the sheet occupies when it opens, and the lower of
  /// the two heights it snaps between.
  final double initialSize;

  /// Dragged below this, the sheet closes instead of shrinking further.
  final double minSize;

  /// The taller snap point.
  final double maxSize;

  @override
  State<PhantomSheet> createState() => _PhantomSheetState();
}

class _PhantomSheetState extends State<PhantomSheet> {
  late double _size = widget.initialSize;
  bool _dragging = false;

  /// Gap left between the status bar and the sheet's top edge at full height,
  /// matching the sliver of the presenting screen an iOS sheet leaves visible.
  static const _topGap = 10.0;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final maxHeight = media.size.height;
    // The panel is anchored to the bottom, so an open keyboard would sit on
    // top of it. Lift it by the inset and cap its height to what is left.
    final keyboard = media.viewInsets.bottom;
    // An iOS sheet's tallest detent stops below the status bar rather than
    // going edge to edge: the screen behind stays visible, the rounded corners
    // and the grabber stay clear of the notch, and nothing inside the panel
    // has to dodge the system clock.
    final ceiling = media.padding.top + _topGap;
    final available = math.max(0.0, maxHeight - keyboard - ceiling);
    final height = math.min(maxHeight * _size, available);

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onClose,
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.45)),
          ),
        ),
        AnimatedPositioned(
          // No animation while a finger is down, or the sheet lags the drag.
          duration: _dragging
              ? Duration.zero
              : const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          left: 0,
          right: 0,
          bottom: keyboard,
          height: height,
          child: _panel(maxHeight),
        ),
      ],
    );
  }

  Widget _panel(double maxHeight) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Material(
        color: widget.theme.background,
        child: Column(
          children: [
            _Handle(
              theme: widget.theme,
              onDragStart: () => setState(() => _dragging = true),
              onDragUpdate: (dy) => setState(() {
                // Floor below minSize, not a constant: the drag has to be
                // able to cross the close threshold for the gesture to work
                // at all, whatever minSize the caller chose.
                _size = (_size - dy / maxHeight)
                    .clamp(widget.minSize / 2, widget.maxSize);
              }),
              onDragEnd: _settle,
            ),
            Expanded(
              child: PhantomThemeProvider(
                theme: widget.theme,
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: ThemeData.dark(),
                  // A nested MaterialApp for its Navigator: without one, the
                  // panel's pushes land on the app's root navigator and cover
                  // the screen the sheet exists to sit beside.
                  //
                  // It builds its MediaQuery from the FlutterView, so it
                  // inherits the window's padding and insets no matter what
                  // this subtree wraps it in — hence stripping them here,
                  // inside, where it also reaches every pushed route:
                  //  - top padding would push the panel's AppBar down by the
                  //    status bar height, although the sheet's edge is
                  //    nowhere near it;
                  //  - the bottom inset is already handled by lifting the
                  //    whole sheet, and applying it again in here would
                  //    collapse the content to nothing.
                  builder: (context, child) {
                    // One copyWith rather than nested remove* helpers: each of
                    // those reads the MediaQuery at the context it is given,
                    // so nesting them with the same context makes the inner
                    // one restore what the outer just stripped.
                    final media = MediaQuery.of(context);
                    return MediaQuery(
                      data: media.copyWith(
                        padding: media.padding.copyWith(top: 0),
                        viewPadding: media.viewPadding.copyWith(top: 0),
                        viewInsets: media.viewInsets.copyWith(bottom: 0),
                      ),
                      child: child!,
                    );
                  },
                  home: PhantomView(
                    onClose: widget.onClose,
                    onToggleButton: widget.onToggleButton,
                    buttonHidden: widget.buttonHidden,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Snap to whichever height is nearer, or close if dragged down past [minSize].
  void _settle() {
    if (_size < widget.minSize) {
      // Reset before closing: PhantomSheet is exported, and a caller whose
      // onClose hides it rather than unmounting it would otherwise get the
      // sheet back mid-drag and below its close threshold.
      setState(() {
        _dragging = false;
        _size = widget.initialSize;
      });
      widget.onClose();
      return;
    }
    final toInitial = (_size - widget.initialSize).abs();
    final toMax = (_size - widget.maxSize).abs();
    setState(() {
      _dragging = false;
      _size = toInitial <= toMax ? widget.initialSize : widget.maxSize;
    });
  }
}

class _Handle extends StatelessWidget {
  const _Handle({
    required this.theme,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final PhantomTheme theme;
  final VoidCallback onDragStart;
  final void Function(double dy) onDragUpdate;
  final VoidCallback onDragEnd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Opaque so the whole strip drags, not just the 36 visible pixels.
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: (_) => onDragStart(),
      onVerticalDragUpdate: (details) => onDragUpdate(details.delta.dy),
      onVerticalDragEnd: (_) => onDragEnd(),
      onVerticalDragCancel: onDragEnd,
      child: SizedBox(
        height: 28,
        child: Center(
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: theme.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}
