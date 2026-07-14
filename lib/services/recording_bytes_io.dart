import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// Where the recorder should write. Mobile and desktop need a real writable
/// file; the take is temporary because the durable copy lives in the bucket.
Future<String> recordingTargetPath(String stepId, String fileExtension) async {
  final directory = await getTemporaryDirectory();

  return '${directory.path}/$stepId.$fileExtension';
}

/// On mobile and desktop the recorder writes a real file and returns its path.
Future<Uint8List> readRecordingBytes(String source) {
  return File(source).readAsBytes();
}

/// Nothing to release: the file is deleted after a successful upload by the
/// caller, and the OS reclaims the temp directory regardless.
Future<void> releaseRecording(String source) async {
  final file = File(source);

  if (await file.exists()) {
    await file.delete();
  }
}
