import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tasilla/services/submission_service.dart';
import 'package:tasilla/widgets/writing_submitter.dart';

/// A file picker and a bucket that live entirely in memory, so the whole flow —
/// type or pick, then send — can be driven without a file dialog or a network.
class _FakeBackend extends WritingSubmitterBackend {
  PickedWriting? picks;
  bool failSubmit;

  final List<String> typed = [];
  final List<PickedWriting> files = [];

  _FakeBackend({this.picks, this.failSubmit = false});

  @override
  Future<PickedWriting?> pickFile() async => picks;

  @override
  Future<void> submitTyped({
    required String learningStepId,
    required String text,
  }) async {
    if (failSubmit) {
      throw const SubmissionReviewException('Could not save your work.');
    }

    typed.add(text);
  }

  @override
  Future<void> submitFile({
    required String learningStepId,
    required PickedWriting file,
  }) async {
    if (failSubmit) {
      throw const SubmissionReviewException('Could not save your work.');
    }

    files.add(file);
  }
}

Future<void> _pump(
  WidgetTester tester,
  _FakeBackend backend, {
  Future<void> Function()? onSubmitted,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: WritingSubmitter(
          learningStepId: 'A1-EXP-001',
          minSentences: 3,
          onSubmitted: onSubmitted ?? () async {},
          backend: backend,
        ),
      ),
    ),
  );
}

const _text = ValueKey('writing_submitter_text');
const _send = ValueKey('writing_submitter_send');
const _pick = ValueKey('writing_submitter_pick');
const _error = ValueKey('writing_submitter_error');

PickedWriting _photo() => PickedWriting(
  fileName: 'homework.jpg',
  bytes: Uint8List.fromList([1, 2, 3, 4]),
);

void main() {
  testWidgets('Send stays disabled until the student types something', (
    tester,
  ) async {
    await _pump(tester, _FakeBackend());

    final send = tester.widget<FilledButton>(find.byKey(_send));
    expect(send.onPressed, isNull);

    await tester.enterText(find.byKey(_text), 'I go to school every day.');
    await tester.pump();

    final ready = tester.widget<FilledButton>(find.byKey(_send));
    expect(ready.onPressed, isNotNull);
  });

  testWidgets('a student types an answer and sends it', (tester) async {
    final backend = _FakeBackend();
    var submittedCallbacks = 0;

    await _pump(tester, backend, onSubmitted: () async => submittedCallbacks++);

    await tester.enterText(find.byKey(_text), 'My name is Ana. I am nine.');
    await tester.pump();
    await tester.tap(find.byKey(_send));
    await tester.pump();
    await tester.pump();

    expect(backend.typed, ['My name is Ana. I am nine.']);
    expect(backend.files, isEmpty);
    expect(submittedCallbacks, 1);
  });

  testWidgets('a student picks a photo and sends it', (tester) async {
    final backend = _FakeBackend(picks: _photo());
    var submittedCallbacks = 0;

    await _pump(tester, backend, onSubmitted: () async => submittedCallbacks++);

    // Switch to the "send a photo" medium.
    await tester.tap(find.text('Send a photo'));
    await tester.pump();

    await tester.tap(find.byKey(_pick));
    await tester.pump();

    expect(find.text('homework.jpg'), findsOneWidget);

    await tester.tap(find.byKey(_send));
    await tester.pump();
    await tester.pump();

    expect(backend.files, hasLength(1));
    expect(backend.files.single.fileName, 'homework.jpg');
    expect(backend.typed, isEmpty);
    expect(submittedCallbacks, 1);
  });

  testWidgets('a failed send surfaces the reason and does not call back', (
    tester,
  ) async {
    final backend = _FakeBackend(failSubmit: true);
    var submittedCallbacks = 0;

    await _pump(tester, backend, onSubmitted: () async => submittedCallbacks++);

    await tester.enterText(find.byKey(_text), 'Some writing.');
    await tester.pump();
    await tester.tap(find.byKey(_send));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(_error), findsOneWidget);
    expect(find.text('Could not save your work.'), findsOneWidget);
    expect(submittedCallbacks, 0);
  });
}
