import 'package:flutter_test/flutter_test.dart';
import 'package:tasilla/data/a1_content_loader.dart';
import 'package:tasilla/data/learning_path_data.dart';
import 'package:tasilla/models/learning_enums.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadA1Content();
  });

  test('A1 launch roadmap exposes 20 topics across five core skills', () {
    final roadSteps = getA1RoadmapSteps();
    expect(roadSteps, hasLength(100));
    expect(roadSteps.first.id, 'A1-T01-VOC');
    expect(roadSteps.last.id, 'A1-T20-WRI');
    expect(roadSteps.every((step) =>
      step.levelId == 'a1' &&
      step.skillId == a1RoadmapSkillId &&
      step.cefrLevel == 'A1' &&
      step.activityKind == ActivityKind.coreActivity &&
      step.canDoStatement.isNotEmpty), true);
  });

  test('skill paths reuse published TASILLA A1 core experiences', () {
    for (final skill in learningSkillDefinitions) {
      final steps = getLearningPathStepsBySkill(skill.id);
      expect(steps, hasLength(20));
      expect(steps.every((step) => getA1LearningExperienceById(step.id) != null), true);
      expect(steps.every((step) => step.skillId == skill.id), true);
    }
  });

  test('A1 roadmap is backed by the current package IDs', () {
    final ids = getA1RoadmapSteps().map((step) => step.id).toSet();
    for (var topic = 1; topic <= 20; topic++) {
      final number = topic.toString().padLeft(2, '0');
      for (final suffix in ['VOC', 'LIS', 'REA', 'SPE', 'WRI']) {
        expect(ids, contains('A1-T$number-$suffix'));
      }
    }
  });
}
