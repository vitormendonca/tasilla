import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:record/record.dart';
import 'package:tasilla/services/submission_service.dart';
import 'package:tasilla/widgets/speaking_recorder.dart';

/// A microphone and a bucket that live entirely in memory, so the whole flow —
/// permission, record, cap, play back, re-record, upload — can be driven without
/// hardware or a network.
class _FakeBackend extends SpeakingRecorderBackend {
  bool permitted;
  bool failUpload;
  String? stopReturns;

  int startCount = 0;
  int cancelCount = 0;
  int releaseCount = 0;
  final List<Uint8List> uploaded = [];

  _FakeBackend({
    this.permitted = true,
    this.failUpload = false,
    this.stopReturns = 'blob:take-1',
  });

  @override
  Future<bool> hasPermission() async => permitted;

  @override
  Future<RecordingFormat> resolveFormat() async => const RecordingFormat(
    encoder: AudioEncoder.aacLc,
    fileExtension: 'm4a',
    contentType: 'audio/mp4',
  );

  @override
  Future<String> targetPath(String stepId, String fileExtension) async =>
      '/tmp/$stepId.$fileExtension';

  @override
  Future<void> start(RecordingFormat format, String path) async {
    startCount++;
  }

  @override
  Future<String?> stop() async => stopReturns;

  @override
  Future<void> cancel() async {
    cancelCount++;
  }

  @override
  Future<Uint8List> bytesOf(String source) async =>
      Uint8List.fromList([1, 2, 3, 4]);

  @override
  Future<void> release(String source) async {
    releaseCount++;
  }

  @override
  Future<void> upload({
    required String learningStepId,
    required Uint8List bytes,
    required RecordingFormat format,
  }) async {
    if (failUpload) {
      throw const SubmissionReviewException('Could not upload your work.');
    }

    uploaded.add(bytes);
  }

  @override
  void dispose() {}
}

Future<void> _pump(
  WidgetTester tester,
  _FakeBackend backend, {
  int maxSeconds = 60,
  Future<void> Function()? onSubmitted,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SpeakingRecorder(
          learningStepId: 'A1-EXP-001',
          maxRecordingSeconds: maxSeconds,
          onSubmitted: onSubmitted ?? () async {},
          backend: backend,
        ),
      ),
    ),
  );
}

const _start = ValueKey('speaking_recorder_start');
const _stop = ValueKey('speaking_recorder_stop');
const _submit = ValueKey('speaking_recorder_submit');
const _rerecord = ValueKey('speaking_recorder_rerecord');
const _error = ValueKey('speaking_recorder_error');

void main() {
  testWidgets('a student records, hears it back, and sends it', (tester) async {
    final backend = _FakeBackend();
    var submittedCallbacks = 0;

    await _pump(tester, backend, onSubmitted: () async => submittedCallbacks++);

    await tester.tap(find.byKey(_start));
    await tester.pump();

    expect(backend.startCount, 1);
    expect(find.byKey(_stop), findsOneWidget);

    await tester.tap(find.byKey(_stop));
    await tester.pump();

    // Playback comes before sending: the student must be able to hear what the
    // teacher is about to hear.
    expect(find.byKey(_submit), findsOneWidget);
    expect(find.byKey(_rerecord), findsOneWidget);

    await tester.tap(find.byKey(_submit));

    // Not pumpAndSettle: while the upload runs the widget shows a spinner, and
    // in the app the lesson replaces it with the status card the moment the
    // submission lands. Settling here would wait on an animation nothing stops.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(backend.uploaded, hasLength(1));
    expect(backend.uploaded.single, Uint8List.fromList([1, 2, 3, 4]));
    expect(submittedCallbacks, 1);

    // The uploaded take is released rather than left pinned in browser memory.
    expect(backend.releaseCount, 1);
  });

  testWidgets('the task cap stops the recording on its own', (tester) async {
    final backend = _FakeBackend();

    await _pump(tester, backend, maxSeconds: 3);

    await tester.tap(find.byKey(_start));
    await tester.pump();
    expect(find.byKey(_stop), findsOneWidget);

    // Left running, a nervous student would upload minutes of silence and the
    // teacher would have to sit through it. The task's own cap ends the take.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.byKey(_stop), findsNothing);
    expect(find.byKey(_submit), findsOneWidget);
    expect(backend.uploaded, isEmpty);
  });

  testWidgets('re-recording throws the take away without uploading it', (
    tester,
  ) async {
    final backend = _FakeBackend();

    await _pump(tester, backend);

    await tester.tap(find.byKey(_start));
    await tester.pump();
    await tester.tap(find.byKey(_stop));
    await tester.pump();

    await tester.tap(find.byKey(_rerecord));
    await tester.pumpAndSettle();

    // Nothing left the device, and the discarded take is released rather than
    // left pinned in memory.
    expect(backend.uploaded, isEmpty);
    expect(backend.releaseCount, 1);
    expect(find.byKey(_start), findsOneWidget);

    await tester.tap(find.byKey(_start));
    await tester.pump();
    expect(backend.startCount, 2);
  });

  testWidgets('a refused microphone is explained, not silently ignored', (
    tester,
  ) async {
    final backend = _FakeBackend(permitted: false);

    await _pump(tester, backend);

    await tester.tap(find.byKey(_start));
    await tester.pumpAndSettle();

    expect(backend.startCount, 0);
    expect(find.byKey(_error), findsOneWidget);
    expect(find.textContaining('microphone'), findsOneWidget);
  });

  testWidgets('a failed upload keeps the take so it can be retried', (
    tester,
  ) async {
    final backend = _FakeBackend(failUpload: true);

    await _pump(tester, backend);

    await tester.tap(find.byKey(_start));
    await tester.pump();
    await tester.tap(find.byKey(_stop));
    await tester.pump();
    await tester.tap(find.byKey(_submit));
    await tester.pumpAndSettle();

    // Losing a student's recording because the network blipped would make them
    // perform it again for no reason. The take survives; Send is still there.
    expect(find.byKey(_error), findsOneWidget);
    expect(find.byKey(_submit), findsOneWidget);
    expect(backend.releaseCount, 0);
  });

  testWidgets('an empty recording is reported rather than sent', (tester) async {
    final backend = _FakeBackend(stopReturns: null);

    await _pump(tester, backend);

    await tester.tap(find.byKey(_start));
    await tester.pump();
    await tester.tap(find.byKey(_stop));
    await tester.pumpAndSettle();

    expect(find.byKey(_error), findsOneWidget);
    expect(find.byKey(_start), findsOneWidget);
    expect(backend.uploaded, isEmpty);
  });
}
