import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('domain 層不得 import flutter', () {
    final domainDir = Directory('lib/domain');
    if (!domainDir.existsSync()) return; // no domain files yet — pass

    final dartFiles = domainDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

    for (final file in dartFiles) {
      final content = file.readAsStringSync();
      final lines = content.split('\n');
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.contains("import 'package:flutter/") ||
            line.contains('import "package:flutter/')) {
          fail(
            'domain 層不得 import flutter\n'
            '  檔案: ${file.path}\n'
            '  行號: ${i + 1}\n'
            '  內容: ${line.trim()}',
          );
        }
      }
    }
  });
}
