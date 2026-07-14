/// Reads a finished recording into bytes so it can be uploaded.
///
/// The `record` package hands back a different kind of string per platform:
/// a `blob:` object URL on web, a real file path everywhere else. Both are
/// opaque handles to the same recording, so the difference is resolved here and
/// nowhere else — callers just get bytes.
library;

export 'recording_bytes_io.dart'
    if (dart.library.js_interop) 'recording_bytes_web.dart';
