import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/submission_service.dart';
import '../theme/app_theme.dart';

/// How the student chose to hand the writing in.
enum WritingMedium { typed, handwritten }

/// A page the student picked off their device: a photo of handwriting, or a PDF.
class PickedWriting {
  final String fileName;
  final Uint8List bytes;

  const PickedWriting({required this.fileName, required this.bytes});

  String get fileExtension {
    final dot = fileName.lastIndexOf('.');

    return dot == -1 ? 'jpg' : fileName.substring(dot + 1).toLowerCase();
  }

  /// Storage serves what it is told, and a browser trusts it. Naming the type
  /// correctly is what makes the teacher's preview render instead of download.
  String get contentType {
    switch (fileExtension) {
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      case 'heic':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }
}

/// Submits a writing task, typed or photographed.
///
/// The choice is the student's, not the lesson's: plenty of A1 learners write
/// far more freely by hand than into a text box, and the teacher reviews the
/// same work either way.
class WritingSubmitter extends StatefulWidget {
  final String learningStepId;
  final int minSentences;

  final Future<void> Function() onSubmitted;

  @visibleForTesting
  final WritingSubmitterBackend? backend;

  const WritingSubmitter({
    super.key,
    required this.learningStepId,
    required this.minSentences,
    required this.onSubmitted,
    this.backend,
  });

  @override
  State<WritingSubmitter> createState() => _WritingSubmitterState();
}

/// The file-picker-and-network half, behind a seam so the flow can be tested
/// without a file dialog or a live bucket.
class WritingSubmitterBackend {
  Future<PickedWriting?> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'heic', 'pdf'],
      withData: true,
    );

    final file = result?.files.singleOrNull;

    if (file == null || file.bytes == null) {
      return null;
    }

    return PickedWriting(fileName: file.name, bytes: file.bytes!);
  }

  Future<void> submitTyped({
    required String learningStepId,
    required String text,
  }) {
    return SubmissionService.submitOrResubmit(
      learningStepId: learningStepId,
      skill: 'writing',
      submissionType: 'text',
      textContent: text,
    );
  }

  Future<void> submitFile({
    required String learningStepId,
    required PickedWriting file,
  }) async {
    final path = await SubmissionService.uploadSubmissionFile(
      learningStepId: learningStepId,
      bytes: file.bytes,
      fileExtension: file.fileExtension,
      contentType: file.contentType,
    );

    await SubmissionService.submitOrResubmit(
      learningStepId: learningStepId,
      skill: 'writing',
      submissionType: 'file',
      filePath: path,
    );
  }
}

class _WritingSubmitterState extends State<WritingSubmitter> {
  late final WritingSubmitterBackend _backend =
      widget.backend ?? WritingSubmitterBackend();

  final TextEditingController _controller = TextEditingController();

  WritingMedium _medium = WritingMedium.typed;
  PickedWriting? _picked;
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canSend {
    if (_sending) return false;

    return _medium == WritingMedium.typed
        ? _controller.text.trim().isNotEmpty
        : _picked != null;
  }

  Future<void> _pick() async {
    setState(() => _error = null);

    try {
      final picked = await _backend.pickFile();

      if (!mounted || picked == null) return;

      setState(() => _picked = picked);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not open that file. Please try another.');
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    final picked = _picked;

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      if (_medium == WritingMedium.typed) {
        await _backend.submitTyped(
          learningStepId: widget.learningStepId,
          text: text,
        );
      } else if (picked != null) {
        await _backend.submitFile(
          learningStepId: widget.learningStepId,
          file: picked,
        );
      }

      await widget.onSubmitted();
    } on SubmissionReviewException catch (error) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = 'Could not send your work. Please try again.';
      });
    }
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
            'Your writing',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Type your answer, or write it on paper and send a photo. Your '
            'teacher will read it and give you feedback.',
            style: TextStyle(fontSize: 12, color: textMuted, height: 1.4),
          ),
          const SizedBox(height: 12),
          SegmentedButton<WritingMedium>(
            segments: const [
              ButtonSegment(
                value: WritingMedium.typed,
                icon: Icon(Icons.keyboard_outlined, size: 17),
                label: Text('Type it'),
              ),
              ButtonSegment(
                value: WritingMedium.handwritten,
                icon: Icon(Icons.photo_camera_outlined, size: 17),
                label: Text('Send a photo'),
              ),
            ],
            selected: {_medium},
            onSelectionChanged: _sending
                ? null
                : (selection) => setState(() {
                    _medium = selection.first;
                    _error = null;
                  }),
          ),
          const SizedBox(height: 12),
          if (_medium == WritingMedium.typed)
            _typedField(textPrimary: textPrimary, textMuted: textMuted, border: border)
          else
            _filePicker(textPrimary: textPrimary, textMuted: textMuted),
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton.icon(
                key: const ValueKey('writing_submitter_send'),
                onPressed: _canSend ? _send : null,
                icon: _sending
                    ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send, size: 18),
                label: Text(_sending ? 'Sending…' : 'Send to teacher'),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              key: const ValueKey('writing_submitter_error'),
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

  Widget _typedField({
    required Color textPrimary,
    required Color textMuted,
    required Color border,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          key: const ValueKey('writing_submitter_text'),
          controller: _controller,
          enabled: !_sending,
          maxLines: 6,
          minLines: 4,
          textCapitalization: TextCapitalization.sentences,
          style: TextStyle(fontSize: 13, color: textPrimary, height: 1.5),
          decoration: InputDecoration(
            hintText: 'Write your answer here…',
            hintStyle: TextStyle(fontSize: 13, color: textMuted),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: border),
            ),
          ),
          // Send only lights up once there is something to send.
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 6),
        Text(
          'At least ${widget.minSentences} sentences.',
          style: TextStyle(fontSize: 11, color: textMuted),
        ),
      ],
    );
  }

  Widget _filePicker({required Color textPrimary, required Color textMuted}) {
    final picked = _picked;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          key: const ValueKey('writing_submitter_pick'),
          onPressed: _sending ? null : _pick,
          icon: const Icon(Icons.upload_file_outlined, size: 18),
          label: Text(picked == null ? 'Choose a photo or PDF' : 'Choose another'),
        ),
        const SizedBox(height: 8),
        Text(
          picked?.fileName ?? 'A photo of your handwriting, or a PDF.',
          key: const ValueKey('writing_submitter_filename'),
          style: TextStyle(
            fontSize: 12,
            color: picked == null ? textMuted : textPrimary,
            fontWeight: picked == null ? FontWeight.w400 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
