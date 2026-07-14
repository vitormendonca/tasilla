import 'package:flutter_test/flutter_test.dart';
import 'package:tasilla/data/a1_learning_experience_data.dart';
import 'package:tasilla/models/learning_enums.dart';
import 'package:tasilla/models/learning_experience.dart';

/// The lessons a launch student can actually reach. EXP 021-040 are hidden for
/// launch, so nothing in them can serve as certificate evidence today.
const _launchScope = 20;

int? _coreNumber(LearningExperience experience) {
  final match = RegExp(r'^A1-EXP-(\d{3})$').firstMatch(experience.id);

  return match == null ? null : int.parse(match.group(1)!);
}

List<LearningExperience> get _launchCoreLessons => a1LearningExperiences
    .where((e) {
      final number = _coreNumber(e);
      return number != null && number <= _launchScope;
    })
    .toList();

void main() {
  group('certificate evidence in the launch scope', () {
    test('four speaking lessons are sent to a teacher', () {
      final reviewed = _launchCoreLessons
          .where((e) => e.speakingTask?.requiresTeacherReview ?? false)
          .map((e) => e.id)
          .toList();

      // Speaking is scored as the teacher's approval rate over these lessons.
      // If this set is ever empty, the speaking score becomes 0/0 and no
      // certificate can issue at all — which is exactly the bug this locks out.
      expect(reviewed, [
        'A1-EXP-001',
        'A1-EXP-009',
        'A1-EXP-012',
        'A1-EXP-013',
      ]);
    });

    test('four writing lessons are sent to a teacher', () {
      final reviewed = _launchCoreLessons
          .where((e) => e.writingTask?.requiresTeacherReview ?? false)
          .map((e) => e.id)
          .toList();

      expect(reviewed, [
        'A1-EXP-008',
        'A1-EXP-016',
        'A1-EXP-018',
        'A1-EXP-020',
      ]);
    });

    test('no lesson is evidence for two skills at once', () {
      // The standard gates the four skills independently. A lesson that counted
      // as both speaking and writing evidence would let one piece of work clear
      // two gates, so a reviewed lesson must carry exactly one reviewed task.
      //
      // The final exam is the one exception, and deliberately so: it examines
      // every skill in one sitting and is scored as final_exam_score, not as
      // per-skill evidence. Per-skill aggregation must therefore skip it — count
      // it and a student's exam speaking would inflate their speaking gate.
      for (final experience in a1LearningExperiences) {
        if (experience.id == 'A1-FINAL-EXAM') {
          continue;
        }

        final speaking = experience.speakingTask?.requiresTeacherReview ?? false;
        final writing = experience.writingTask?.requiresTeacherReview ?? false;

        expect(
          speaking && writing,
          isFalse,
          reason: '${experience.id} is reviewed as both speaking and writing',
        );
      }
    });

    test('every reviewed lesson carries a rubric the teacher can grade against', () {
      final reviewed = a1LearningExperiences.where(
        (e) => e.requiresTeacherReview,
      );

      expect(reviewed, isNotEmpty);

      for (final experience in reviewed) {
        // Without a visible rubric, approval is just vibes — and an approval
        // that is just vibes cannot back a certificate.
        expect(
          experience.rubric?.criteria,
          isNotEmpty,
          reason: '${experience.id} is teacher-reviewed but has no rubric',
        );
      }
    });

    test('a reviewed lesson is evidence for its own primary skill', () {
      for (final experience in _launchCoreLessons) {
        if (experience.speakingTask?.requiresTeacherReview ?? false) {
          expect(experience.primarySkill, LearningSkill.speaking);
        }

        if (experience.writingTask?.requiresTeacherReview ?? false) {
          // Writing evidence comes from writing-primary lessons, plus the two
          // mixed lessons whose free-response task is substantial enough.
          expect(
            experience.primarySkill,
            anyOf(LearningSkill.writing, LearningSkill.mixed),
          );
        }
      }
    });
  });
}
