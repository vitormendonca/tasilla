import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// The browser records into memory and hands back a blob, so there is no path
/// to write to. The recorder ignores this value on web.
Future<String> recordingTargetPath(String stepId, String fileExtension) async {
  return '';
}

/// On web the recorder returns a `blob:` object URL rather than a file. Fetching
/// it is how the bytes come back out of the browser's blob store.
Future<Uint8List> readRecordingBytes(String source) async {
  final response = await web.window.fetch(source.toJS).toDart;
  final buffer = await response.arrayBuffer().toDart;

  return buffer.toDart.asUint8List();
}

/// A blob URL pins its blob in memory for the life of the document. Revoking it
/// after upload is what lets a student re-record several times without the page
/// slowly accumulating every take they discarded.
Future<void> releaseRecording(String source) async {
  web.URL.revokeObjectURL(source);
}
