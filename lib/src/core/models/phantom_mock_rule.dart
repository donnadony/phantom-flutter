import 'dart:convert';

/// HTTP methods a mock rule or response can be bound to. `ANY` matches all.
const phantomHttpMethods = ['ANY', 'GET', 'POST', 'PUT', 'DELETE'];

class PhantomMockResponse {
  final String id;
  String name;
  String httpMethod;
  int statusCode;
  String responseBody;

  PhantomMockResponse({
    required this.id,
    required this.name,
    this.httpMethod = 'ANY',
    this.statusCode = 200,
    this.responseBody = '{\n  \n}',
  });

  PhantomMockResponse copyWith({
    String? name,
    String? httpMethod,
    int? statusCode,
    String? responseBody,
  }) {
    return PhantomMockResponse(
      id: id,
      name: name ?? this.name,
      httpMethod: httpMethod ?? this.httpMethod,
      statusCode: statusCode ?? this.statusCode,
      responseBody: responseBody ?? this.responseBody,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'httpMethod': httpMethod,
        'statusCode': statusCode,
        'responseBody': responseBody,
      };

  factory PhantomMockResponse.fromJson(Map<String, dynamic> json) {
    return PhantomMockResponse(
      id: json['id'] as String,
      name: json['name'] as String,
      httpMethod: json['httpMethod'] as String? ?? 'ANY',
      statusCode: json['statusCode'] as int? ?? 200,
      responseBody: json['responseBody'] as String? ?? '',
    );
  }
}

class PhantomMockRule {
  final String id;
  bool isEnabled;
  String urlPattern;
  String httpMethod;
  List<PhantomMockResponse> responses;
  String? activeResponseId;
  String ruleDescription;
  final DateTime createdAt;

  PhantomMockRule({
    required this.id,
    this.isEnabled = true,
    required this.urlPattern,
    this.httpMethod = 'ANY',
    this.responses = const [],
    this.activeResponseId,
    this.ruleDescription = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  PhantomMockResponse? get activeResponse {
    if (responses.isEmpty) return null;
    if (activeResponseId == null) return responses.first;
    return responses.cast<PhantomMockResponse?>().firstWhere(
          (r) => r!.id == activeResponseId,
          orElse: () => responses.first,
        );
  }

  PhantomMockRule copyWith({
    bool? isEnabled,
    String? urlPattern,
    String? httpMethod,
    List<PhantomMockResponse>? responses,
    String? activeResponseId,
    String? ruleDescription,
  }) {
    return PhantomMockRule(
      id: id,
      isEnabled: isEnabled ?? this.isEnabled,
      urlPattern: urlPattern ?? this.urlPattern,
      httpMethod: httpMethod ?? this.httpMethod,
      responses: responses ?? this.responses,
      activeResponseId: activeResponseId ?? this.activeResponseId,
      ruleDescription: ruleDescription ?? this.ruleDescription,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'isEnabled': isEnabled,
        'urlPattern': urlPattern,
        'httpMethod': httpMethod,
        'responses': responses.map((r) => r.toJson()).toList(),
        'activeResponseId': activeResponseId,
        'ruleDescription': ruleDescription,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PhantomMockRule.fromJson(Map<String, dynamic> json) {
    return PhantomMockRule(
      id: json['id'] as String,
      isEnabled: json['isEnabled'] as bool? ?? true,
      urlPattern: json['urlPattern'] as String,
      httpMethod: json['httpMethod'] as String? ?? 'ANY',
      responses: (json['responses'] as List<dynamic>?)
              ?.map((r) =>
                  PhantomMockResponse.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
      activeResponseId: json['activeResponseId'] as String?,
      ruleDescription: json['ruleDescription'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  static String encodeRules(List<PhantomMockRule> rules) {
    return jsonEncode(rules.map((r) => r.toJson()).toList());
  }

  static List<PhantomMockRule> decodeRules(String jsonString) {
    final list = jsonDecode(jsonString) as List<dynamic>;
    return list
        .map((r) => PhantomMockRule.fromJson(r as Map<String, dynamic>))
        .toList();
  }
}
