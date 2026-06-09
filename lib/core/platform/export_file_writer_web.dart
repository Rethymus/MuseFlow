import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart';

Future<void> writeExportFile(String path, String content) async {
  final filename = path.split(RegExp(r'[/\\]')).last;
  final bytes = utf8.encode(content);
  final blob = Blob(
    [bytes.toJS].toJS,
    BlobPropertyBag(type: 'text/plain;charset=utf-8'),
  );
  final url = URL.createObjectURL(blob);

  HTMLAnchorElement()
    ..href = url
    ..download = filename.isEmpty ? 'museflow-export.txt' : filename
    ..click();

  URL.revokeObjectURL(url);
}
