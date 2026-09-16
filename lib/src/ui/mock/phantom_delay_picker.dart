import 'package:flutter/material.dart';

import '../../theme/phantom_theme.dart';

const phantomMockDelays = <int>[0, 500, 1000, 3000, 10000];

String phantomMockDelayLabel(int milliseconds) {
  if (milliseconds == 0) return 'None';
  if (milliseconds % 1000 == 0) return '${milliseconds ~/ 1000} s';
  return '${(milliseconds / 1000).toStringAsFixed(1)} s';
}

class PhantomDelayPicker extends StatelessWidget {
  final int delayMs;
  final ValueChanged<int> onChanged;
  final PhantomTheme theme;

  const PhantomDelayPicker({
    super.key,
    required this.delayMs,
    required this.onChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: phantomMockDelays.map((delay) {
        final selected = delayMs == delay;
        return GestureDetector(
          onTap: () => onChanged(delay),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? theme.primary : theme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              phantomMockDelayLabel(delay),
              style: TextStyle(
                color: selected ? theme.onPrimary : theme.onBackground,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
