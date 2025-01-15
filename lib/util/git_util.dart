import 'dart:convert';
import 'dart:io';

abstract final class GitUtil {
  static Future<String?> pubspecVersionChange() async {
    final result = await Process.run(
      'git',
      ['show', 'HEAD', '--', 'pubspec.yaml'],
    );

    if (result.exitCode != 0) {
      stderr.writeln('Error running git command: ${result.stderr}');
      exit(1);
    }

    final lines = LineSplitter.split(result.stdout);
    final versionRegex = RegExp(r'^\+version:\s*(.*)');

    for (final line in lines) {
      final match = versionRegex.firstMatch(line);
      if (match != null) {
        return match.group(1);
      }
    }

    return null;
  }
}
