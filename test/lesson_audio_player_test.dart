import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tasilla/data/a1_learning_experience_data.dart';
import 'package:tasilla/widgets/lesson_audio_player.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every planned A1 audio path resolves to a bundled asset', () async {
    final missing = <String>[];
    for (final experience in a1LearningExperiences) {
      final path = experience.listeningBlock?.audioPath;
      if (path == null || path.trim().isEmpty) continue;
      try {
        await rootBundle.load(path);
      } catch (_) {
        missing.add('${experience.id}: $path');
      }
    }

    expect(
      missing,
      isEmpty,
      reason: 'Missing A1 audio assets:\n${missing.join('\n')}',
    );
  });

  testWidgets('transcript stays hidden until it is allowed', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LessonAudioPlayer(
            audioPath: 'assets/audio/a1/a1_exp_001_meeting_anna.mp3',
            transcript: 'Hello from the transcript.',
            maxPlays: 2,
            allowTranscript: false,
          ),
        ),
      ),
    );

    expect(find.text('Hello from the transcript.'), findsNothing);
    expect(find.text('Show transcript'), findsNothing);
    expect(find.textContaining('transcript unlocks'), findsOneWidget);
  });

  testWidgets('allowed transcript can be shown and hidden', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LessonAudioPlayer(
            audioPath: 'assets/audio/a1/a1_exp_001_meeting_anna.mp3',
            transcript: 'Hello from the transcript.',
            maxPlays: 2,
            allowTranscript: true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show transcript'));
    await tester.pump();
    expect(find.text('Hello from the transcript.'), findsOneWidget);

    await tester.tap(find.text('Hide transcript'));
    await tester.pump();
    expect(find.text('Hello from the transcript.'), findsNothing);
  });
}
