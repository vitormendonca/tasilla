import 'dart:convert';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart' show rootBundle;

import '../models/learning_experience.dart';
import 'a1_content_manifest.dart';

/// Loads the TASILLA A1 course content from bundled JSON assets.
///
/// This replaces the auto-generated seed content in
/// `a1_learning_experience_data.dart` (kept on disk, no longer referenced).
/// The JSON files in assets/content/a1/ are generated from the authored
/// txt sources by tools/convert_tasilla_content.py and parsed here through
/// [LearningExperience.fromJson] - the schema's single source of truth.
///
/// Usage: `await loadA1Content()` once during app bootstrap (see main.dart).
/// After that, [getA1LearningExperiences] and [getA1LearningExperienceById]
/// are synchronous drop-in replacements for the old seed-data API.

const String a1ContentVersion = 'a1.tasilla.v1';

List<LearningExperience> _experiences = const [];
Map<String, LearningExperience> _byId = const {};

/// Reads every asset listed in the generated manifest, exactly once.
Future<void> loadA1Content() async {
  if (_experiences.isNotEmpty) {
    return;
  }

  final loaded = <LearningExperience>[];
  for (final path in a1ContentAssetPaths) {
    final raw = await rootBundle.loadString(path);
    final decoded = json.decode(raw);
    if (decoded is Map<String, dynamic>) {
      loaded.add(LearningExperience.fromJson(decoded));
    }
  }

  loaded.sort((a, b) => a.order.compareTo(b.order));
  _experiences = List.unmodifiable(loaded);
  _byId = {for (final experience in _experiences) experience.id: experience};
}

/// Injects content directly - used by tests, which read the JSON files from
/// disk instead of the asset bundle.
@visibleForTesting
void debugSetA1Content(List<LearningExperience> experiences) {
  final sorted = [...experiences]..sort((a, b) => a.order.compareTo(b.order));
  _experiences = List.unmodifiable(sorted);
  _byId = {for (final experience in _experiences) experience.id: experience};
}

/// True once [loadA1Content] has completed.
bool get a1ContentLoaded => _experiences.isNotEmpty;

List<LearningExperience> getA1LearningExperiences() {
  assert(
    _experiences.isNotEmpty,
    'A1 content not loaded yet - call loadA1Content() during bootstrap.',
  );
  return _experiences;
}

LearningExperience? getA1LearningExperienceById(String id) {
  return _byId[id];
}
