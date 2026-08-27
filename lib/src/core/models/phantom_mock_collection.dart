import 'dart:convert';

import 'phantom_mock_rule.dart';

/// Import/export envelope for mock rules.
///
/// Matches the shape produced by phantom-ios `exportCollection`, so collections
/// can be moved between the iOS and Flutter toolkits unchanged.
class PhantomMockCollection {
  final String name;
  final String description;
  final List<PhantomMockRule> rules;

  const PhantomMockCollection({
    required this.name,
    this.description = '',
    required this.rules,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'rules': rules.map((r) => r.toJson()).toList(),
      };

  factory PhantomMockCollection.fromJson(Map<String, dynamic> json) {
    return PhantomMockCollection(
      name: json['name'] as String? ?? 'Phantom Mocks',
      description: json['description'] as String? ?? '',
      rules: (json['rules'] as List<dynamic>?)
              ?.map((r) => PhantomMockRule.fromJson(r as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  String encode() => const JsonEncoder.withIndent('  ').convert(toJson());

  /// Parses either a full collection object or a bare array of rules, which is
  /// what older exports (and hand-written files) contain.
  static PhantomMockCollection? decode(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is Map<String, dynamic>) {
        return PhantomMockCollection.fromJson(decoded);
      }
      if (decoded is List) {
        return PhantomMockCollection(
          name: 'Phantom Mocks',
          rules: decoded
              .map((r) => PhantomMockRule.fromJson(r as Map<String, dynamic>))
              .toList(),
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
