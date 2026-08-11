import 'dart:convert';

import 'package:flutter/services.dart';

class DreamReading {
  const DreamReading({
    required this.id,
    required this.title,
    required this.body,
    required this.prompt,
  });

  final String id;
  final String title;
  final String body;
  final String prompt;
}

class DreamInterpreter {
  DreamInterpreter._({
    required List<_DreamTheme> themes,
    required this.fallback,
  }) : _themes = themes;

  final List<_DreamTheme> _themes;
  final DreamReading fallback;

  static Future<DreamInterpreter> loadAsset({
    String path = 'assets/content/dream_symbols.json',
  }) async {
    final text = await rootBundle.loadString(path);
    return DreamInterpreter.fromJsonString(text);
  }

  factory DreamInterpreter.fromJsonString(String text) {
    final json = jsonDecode(text) as Map<String, dynamic>;
    final themes = (json['themes'] as List<dynamic>? ?? const [])
        .map((item) => _DreamTheme.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
    final fallback = _readingFromJson(json['fallback'] as Map<String, dynamic>);
    return DreamInterpreter._(themes: themes, fallback: fallback);
  }

  List<DreamReading> interpret(String dream) {
    final normalized = dream.trim().toLowerCase();
    if (normalized.isEmpty) return const [];
    final matches = _themes
        .where((theme) => theme.keywords.any(normalized.contains))
        .take(3)
        .map((theme) => theme.reading)
        .toList(growable: false);
    return matches.isEmpty ? [fallback] : matches;
  }
}

class _DreamTheme {
  const _DreamTheme({required this.keywords, required this.reading});

  final List<String> keywords;
  final DreamReading reading;

  factory _DreamTheme.fromJson(Map<String, dynamic> json) => _DreamTheme(
    keywords: (json['keywords'] as List<dynamic>).cast<String>(),
    reading: _readingFromJson(json),
  );
}

DreamReading _readingFromJson(Map<String, dynamic> json) => DreamReading(
  id: json['id'] as String,
  title: json['title'] as String,
  body: json['body'] as String,
  prompt: json['prompt'] as String,
);
