import 'dart:convert';
import 'package:flutter/services.dart';

// ---------------------------------------------------------------------------
// ScanConfig
// ---------------------------------------------------------------------------
class ScanConfig {
  final int intervalMs;
  final int windowSize;
  final int minHits;
  final double minConfidence;
  final double photoMinConfidence;
  final int topK;

  const ScanConfig({
    required this.intervalMs,
    required this.windowSize,
    required this.minHits,
    required this.minConfidence,
    required this.photoMinConfidence,
    required this.topK,
  });

  factory ScanConfig.fromJson(Map<String, dynamic> json) {
    return ScanConfig(
      intervalMs: json['intervalMs'] as int,
      windowSize: json['windowSize'] as int,
      minHits: json['minHits'] as int,
      minConfidence: (json['minConfidence'] as num).toDouble(),
      photoMinConfidence: (json['photoMinConfidence'] as num).toDouble(),
      topK: json['topK'] as int,
    );
  }
}

// ---------------------------------------------------------------------------
// RetrievalConfig
// ---------------------------------------------------------------------------
class RetrievalConfig {
  final int limit;
  final double minOwnedCoreRatio;

  const RetrievalConfig({
    required this.limit,
    required this.minOwnedCoreRatio,
  });

  factory RetrievalConfig.fromJson(Map<String, dynamic> json) {
    return RetrievalConfig(
      limit: json['limit'] as int,
      minOwnedCoreRatio: (json['minOwnedCoreRatio'] as num).toDouble(),
    );
  }
}

// ---------------------------------------------------------------------------
// LlmConfig
// ---------------------------------------------------------------------------
class LlmConfig {
  final double temperature;
  final double topP;
  final int maxTokens;
  final int contextSize;
  final int timeoutSeconds;
  final int maxRetries;

  const LlmConfig({
    required this.temperature,
    required this.topP,
    required this.maxTokens,
    required this.contextSize,
    required this.timeoutSeconds,
    required this.maxRetries,
  });

  factory LlmConfig.fromJson(Map<String, dynamic> json) {
    return LlmConfig(
      temperature: (json['temperature'] as num).toDouble(),
      topP: (json['topP'] as num).toDouble(),
      maxTokens: json['maxTokens'] as int,
      contextSize: json['contextSize'] as int,
      timeoutSeconds: json['timeoutSeconds'] as int,
      maxRetries: json['maxRetries'] as int,
    );
  }
}

// ---------------------------------------------------------------------------
// AppConfig
// ---------------------------------------------------------------------------
class AppConfig {
  final ScanConfig scan;
  final RetrievalConfig retrieval;
  final LlmConfig llm;
  final List<int> budgetPresets;
  final int defaultBudget;

  const AppConfig({
    required this.scan,
    required this.retrieval,
    required this.llm,
    required this.budgetPresets,
    required this.defaultBudget,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      scan: ScanConfig.fromJson(json['scan'] as Map<String, dynamic>),
      retrieval: RetrievalConfig.fromJson(
          json['retrieval'] as Map<String, dynamic>),
      llm: LlmConfig.fromJson(json['llm'] as Map<String, dynamic>),
      budgetPresets:
          (json['budgetPresets'] as List).cast<int>(),
      defaultBudget: json['defaultBudget'] as int,
    );
  }

  static Future<AppConfig> load() async {
    final raw =
        await rootBundle.loadString('assets/config/app_config.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return AppConfig.fromJson(decoded);
  }
}
