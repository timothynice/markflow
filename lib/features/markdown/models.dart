import 'dart:convert';

class MdVersion {
  final String id;
  final DateTime createdAt;
  final String content;

  MdVersion({required this.id, required this.createdAt, required this.content});

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'content': content,
      };

  factory MdVersion.fromJson(Map<String, dynamic> json) => MdVersion(
        id: json['id'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        content: json['content'] as String,
      );
}

class MdDocument {
  final String id;
  String title;
  String content;
  DateTime updatedAt;
  List<MdVersion> versions;

  MdDocument({
    required this.id,
    required this.title,
    required this.content,
    required this.updatedAt,
    required this.versions,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'updatedAt': updatedAt.toIso8601String(),
        'versions': versions.map((v) => v.toJson()).toList(),
      };

  factory MdDocument.fromJson(Map<String, dynamic> json) => MdDocument(
        id: json['id'] as String,
        title: json['title'] as String,
        content: json['content'] as String,
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        versions: ((json['versions'] as List?) ?? [])
            .map((e) => MdVersion.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());
}
