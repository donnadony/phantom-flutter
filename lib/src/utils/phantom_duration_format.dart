const phantomSlowRequestMs = 1000;

String phantomFormatDuration(int milliseconds) {
  final seconds = milliseconds / 1000;
  if (milliseconds < 1000) return '${seconds.toStringAsFixed(2)} s';
  if (milliseconds < 10000) return '${seconds.toStringAsFixed(1)} s';
  return '${seconds.round()} s';
}
