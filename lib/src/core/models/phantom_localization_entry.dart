enum PhantomLanguage {
  english,
  spanish;

  String get displayName {
    switch (this) {
      case PhantomLanguage.english:
        return 'EN';
      case PhantomLanguage.spanish:
        return 'ES';
    }
  }
}

class PhantomLocalizationEntry {
  final String key;
  final String english;
  final String spanish;
  final String group;

  String get id => '${group}_$key';

  const PhantomLocalizationEntry({
    required this.key,
    required this.english,
    required this.spanish,
    this.group = 'General',
  });

  String value(PhantomLanguage language) {
    switch (language) {
      case PhantomLanguage.english:
        return english;
      case PhantomLanguage.spanish:
        return spanish;
    }
  }
}
