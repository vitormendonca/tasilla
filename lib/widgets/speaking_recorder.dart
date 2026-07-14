import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';

import '../services/recording_bytes.dart';
import '../services/submission_service.dart';
import '../theme/app_theme.dart';
import 'lesson_audio_player.dart';

/// The moment a student proves they can speak. They record, hear themselves
/// back, and re-record as many times as they like before anything is sent —
/// this is about proving ability, not punishing nerves.
enum RecorderStage { idle, recording, recorded, submitting }

/// Records a spoken answer, lets the student listen to it, and uploads the take
/// they choose to a private bucket.
class SpeakingRecorder extends StatefulWidget {
  final String learningStepId;
  final int maxRecordingSeconds;

  /// Called once the submission row exists, so the lesson can show its status.
  final Future<void> Function() onSubmitted;

  /// Swapped out in tests, where there is no microphone and no Supabase.
  @visibleForTesting
  final SpeakingRecorderBackend? backend;

  const SpeakingRecorder({
    super.key,
    required this.learningStepId,
    required this.maxRecordingSeconds,
    required this.onSubmitted,
    this.backend,
  });

  @override
  State<SpeakingRecorder> createState() => _SpeakingRecorderState();
}

/// The device-and-network half of recording, behind a seam. A widget test can
/// exercise every stage of the flow without a microphone or a live bucket.
class SpeakingRecorderBackend {
  final AudioRecorder _recorder = AudioRecorder();

  Future<bool> hasPermission() => _recorder.hasPermission();

  /// AAC is the wanted format, but Safari and Firefox will not encode it. Rather
  /// than refuse to record, fall back to whatever the browser does support and
  /// store the recording under its true extension.
  Future<RecordingFormat> resolveFormat() async {
    if (await _recorder.isEncoderSupported(AudioEncoder.aacLc)) {
      return const RecordingFormat(
        encoder: AudioEncoder.aacLc,
        fileExtension: 'm4a',
        contentType: 'audio/mp4',
      );
    }

    return const RecordingFormat(
      encoder: AudioEncoder.opus,
      fileExtension: 'webm',
      contentType: 'audio/webm',
    );
  }

  Future<void> start(RecordingFormat format, String path) {
    return _recorder.start(RecordConfig(encoder: format.encoder), path: path);
  }

  /// Returns a blob URL on web, a file path elsewhere. Either way it is an
  /// opaque handle the rest of this widget passes around without inspecting.
  Future<String?> stop() => _recorder.stop();

  Future<void> cancel() => _recorder.cancel();

  Future<String> targetPath(String stepId, String fileExtension) {
    return recordingTargetPath(stepId, fileExtension);
  }

  Future<Uint8List> bytesOf(String source) => readRecordingBytes(source);

  Future<void> release(String source) => releaseRecording(source);

  Future<void> upload({
    required String learningStepId,
    required Uint8List bytes,
    required RecordingFormat format,
  }) async {
    final path = await SubmissionService.uploadSubmissionFile(
      learningStepId: learningStepId,
      bytes: bytes,
      fileExtension: format.fileExtension,
      contentType: format.contentType,
    );

    await SubmissionService.submitOrResubmit(
      learningStepId: learningStepId,
      skill: 'speaking',
      submissionType: 'audio',
      filePath: path,
    );
  }

  void dispose() => _recorder.dispose();
}

class RecordingFormat {
  final AudioEncoder encoder;
  final String fileExtension;
  final String contentType;

  const RecordingFormat({
    required this.encoder,
    required this.fileExtension,
    required this.contentType,
  });
}

class _SpeakingRecorderState extends State<SpeakingRecorder> {
  late final SpeakingRecorderBackend _backend =
      widget.backend ?? SpeakingRecorderBackend();

  RecorderStage _stage = RecorderStage.idle;
  RecordingFormat? _format;
  String? _source;
  Timer? _ticker;
  int _elapsedSeconds = 0;
  String? _error;

  int get _remainingSeconds =>
      (widget.maxRecordingSeconds - _elapsedSeconds).clamp(
        0,
        widget.maxRecordingSeconds,
      );

  @override
  void dispose() {
    _ticker?.cancel();
    _backend.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    setState(() => _error = null);

    if (!await _backend.hasPermission()) {
      if (!mounted) return;
      setState(
        () => _error =
            'TASILLA needs the microphone to record your answer. '
            'Allow access and try again.',
      );
      return;
    }

    try {
      final format = await _backend.resolveFormat();
      final path = await _backend.targetPath(
        widget.learningStepId,
        format.fileExtension,
      );

      await _backend.start(format, path);

      if (!mounted) return;

      setState(() {
        _format = format;
        _stage = RecorderStage.recording;
        _elapsedSeconds = 0;
      });

      _startTicker();
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not start recording. Please try again.');
    }
  }

  /// The task's own cap ends the take. Left to run, a nervous student fills a
  /// bucket with silence, and the teacher has to sit through it.
  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      setState(() => _elapsedSeconds++);

      if (_elapsedSeconds >= widget.maxRecordingSeconds) {
        _stopRecording();
      }
    });
  }

  Future<void> _stopRecording() async {
    _ticker?.cancel();

    try {
      final source = await _backend.stop();

      if (!mounted) return;

      if (source == null || source.isEmpty) {
        setState(() {
          _stage = RecorderStage.idle;
          _error = 'That recording came out empty. Please try again.';
        });
        return;
      }

      setState(() {
        _source = source;
        _stage = RecorderStage.recorded;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _stage = RecorderStage.idle;
        _error = 'Could not save that recording. Please try again.';
      });
    }
  }

  /// Throws the take away without uploading it. Nothing has left the device yet,
  /// so a re-record costs the student nothing.
  Future<void> _discard() async {
    final source = _source;

    setState(() {
      _source = null;
      _stage = RecorderStage.idle;
      _elapsedSeconds = 0;
      _error = null;
    });

    if (source != null) {
      await _backend.release(source);
    }
  }

  Future<void> _submit() async {
    final source = _source;
    final format = _format;

    if (source == null || format == null) return;

    setState(() {
      _stage = RecorderStage.submitting;
      _error = null;
    });

    try {
      final bytes = await _backend.bytesOf(source);

      await _backend.upload(
        learningStepId: widget.learningStepId,
        bytes: bytes,
        format: format,
      );

      await _backend.release(source);
      await widget.onSubmitted();
    } on SubmissionReviewException catch (error) {
      if (!mounted) return;
      setState(() {
        _stage = RecorderStage.recorded;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _stage = RecorderStage.recorded;
        _error = 'Could not send your recording. Please try again.';
      });
    }
  }

  String _clock(int seconds) {
    final minutes = seconds ~/ 60;
    final rest = (seconds % 60).toString().padLeft(2, '0');

    return '$minutes:$rest';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark
        ? const Color(0xFFF5F5F0)
        : const Color(0xFF1A1A1A);
    final textMuted = isDark
        ? const Color(0xFF8E8E93)
        : const Color(0xFF706D67);
    final border = isDark
        ? const Color(0xFF2C2C2E)
        : const Color(0xFFE5E2DC);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your recording',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Record your answer, listen to it, and send it when you are happy '
            'with it. Your teacher will listen and give you feedback.',
            style: TextStyle(fontSize: 12, color: textMuted, height: 1.4),
          ),
          const SizedBox(height: 12),
          _stageContent(textPrimary: textPrimary, textMuted: textMuted),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              key: const ValueKey('speaking_recorder_error'),
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.semanticRed,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _stageContent({
    required Color textPrimary,
    required Color textMuted,
  }) {
    switch (_stage) {
      case RecorderStage.idle:
        return Row(
          children: [
            FilledButton.icon(
              key: const ValueKey('speaking_recorder_start'),
              onPressed: _startRecording,
              icon: const Icon(Icons.mic, size: 18),
              label: const Text('Start recording'),
            ),
            const SizedBox(width: 10),
            Text(
              '${widget.maxRecordingSeconds}s max',
              style: TextStyle(fontSize: 12, color: textMuted),
            ),
          ],
        );

      case RecorderStage.recording:
        return Row(
          children: [
            FilledButton.icon(
              key: const ValueKey('speaking_recorder_stop'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.semanticRed,
              ),
              onPressed: _stopRecording,
              icon: const Icon(Icons.stop, size: 18),
              label: const Text('Stop'),
            ),
            const SizedBox(width: 12),
            Icon(Icons.fiber_manual_record, size: 12, color: AppTheme.semanticRed),
            const SizedBox(width: 6),
            Text(
              'Recording  ${_clock(_elapsedSeconds)}  ·  '
              '${_clock(_remainingSeconds)} left',
              style: TextStyle(fontSize: 12, color: textPrimary),
            ),
          ],
        );

      case RecorderStage.recorded:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LessonAudioPlayer(
              key: ValueKey('speaking_recorder_playback_$_source'),
              audioPath: _source!,
              isRemote: kIsWeb,
              isLocalFile: !kIsWeb,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  key: const ValueKey('speaking_recorder_submit'),
                  onPressed: _submit,
                  icon: const Icon(Icons.send, size: 18),
                  label: const Text('Send to teacher'),
                ),
                OutlinedButton.icon(
                  key: const ValueKey('speaking_recorder_rerecord'),
                  onPressed: _discard,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Record again'),
                ),
              ],
            ),
          ],
        );

      case RecorderStage.submitting:
        return Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(
              'Sending your recording…',
              style: TextStyle(fontSize: 12, color: textMuted),
            ),
          ],
        );
    }
  }
}
