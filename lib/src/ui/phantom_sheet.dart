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
    this.initialSize = 0.5,
    this.minSize = 0.25,
    this.maxSize = 1.0,
  });

  final PhantomTheme theme;
  final VoidCallback onClose;

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

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height;

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
          bottom: 0,
          height: maxHeight * _size,
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
                _size = (_size - dy / maxHeight).clamp(0.1, widget.maxSize);
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
                  home: PhantomView(onClose: widget.onClose),
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
