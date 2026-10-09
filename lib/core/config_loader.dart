import 'dart:convert';
import 'package:flutter/services.dart';

/// Stub — loads app_config.json and returns the decoded map.
/// Full implementation deferred to a later task.
Future<dynamic> loadAppConfig() async {
  final raw = await rootBundle.loadString('assets/config/app_config.json');
  return jsonDecode(raw);
}
