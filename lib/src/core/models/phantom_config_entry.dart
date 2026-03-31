enum PhantomConfigType { text, toggle, picker }

class PhantomConfigEntry {
  final String label;
  final String key;
  final String defaultValue;
  final PhantomConfigType type;
  final List<String> options;
  final String group;

  const PhantomConfigEntry({
    required this.label,
    required this.key,
    required this.defaultValue,
    this.type = PhantomConfigType.text,
    this.options = const [],
    this.group = 'General',
  });
}
